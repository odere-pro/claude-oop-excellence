# Reference

Detection heuristics, ORM-specific patterns, grep expressions, thresholds, and false positive guidance for each database antipattern.

## Table of contents

- [God Table](#god-table)
- [Inner-Platform Effect](#inner-platform-effect)
- [EAV Abuse](#eav-abuse)
- [N+1 Query](#n1-query)
- [Thresholds summary](#thresholds-summary)

## God Table

A single table accumulates too many columns, often with many nullable fields and generic names, indicating it has become a dumping ground for unrelated concerns.

### SQL detection

Grep for `CREATE TABLE` statements and count columns between the parentheses.

```
# Count columns in CREATE TABLE
grep -Pzo 'CREATE TABLE[^;]+;' <file> | grep -c ','
```

Indicators:

- More than 20 columns in a single `CREATE TABLE`
- High ratio of `NULL` or `DEFAULT NULL` columns (>50% of total)
- Generic column names: `data`, `value`, `field1`-`fieldN`, `extra`, `misc`, `info`, `blob`, `metadata` (as a catch-all JSON column)
- Multiple `TEXT` or `JSON`/`JSONB` columns without clear domain meaning

### ORM detection

**Prisma** — count fields in a `model` block:

```prisma
model User {
  // >20 fields = warning, >40 = critical
}
```

Grep: `model\s+\w+\s*\{` then count lines until `\}`.

**TypeORM** — count `@Column()` decorators in a single entity class:

```typescript
@Entity()
export class User {
  @Column({ nullable: true }) field1: string; // generic name
  @Column({ nullable: true }) data: string; // generic name
}
```

Grep: `@Column` within a class body. Count `nullable:\s*true` occurrences.

**Sequelize** — count properties in `define()` or `init()`:

```javascript
Model.init(
  {
    /* >20 properties */
  },
  { sequelize },
);
```

**SQLAlchemy** — count `Column()` calls in a class:

```python
class User(Base):
    field1 = Column(String, nullable=True)
```

**ActiveRecord** — check migration files for `create_table` with many columns, or `schema.rb` for table definitions.

### False positive guidance

- Tables with many columns that are all non-nullable and domain-specific (e.g., financial ledger with 25 required fields) may be legitimate.
- Audit/log tables that intentionally capture wide data are acceptable.
- If columns follow a clear naming convention tied to a single domain, reduce severity by one level.

## Inner-Platform Effect

Application code reimplements features the database already provides: custom query languages, custom indexing, custom transaction management.

### Detection patterns

**Custom query builder** — classes that construct SQL strings or query objects instead of using ORM/driver query methods:

```typescript
class QueryBuilder {
  where(field: string, op: string, value: any) { ... }
  orderBy(field: string) { ... }
  build(): string { ... }
}
```

Grep: `class\s+\w*Query\w*Builder`, `class\s+\w*QueryEngine`, `buildQuery|buildSql|toSql`

Note: ORMs themselves (Knex, Prisma, TypeORM QueryBuilder) are not antipatterns. Flag only custom implementations that duplicate what the ORM already provides.

**Application-level indexing** — maintaining in-memory indexes or lookup tables that mirror database indexes:

```typescript
const index = new Map<string, Record[]>();
// Populating from DB, then querying the Map instead of DB
```

Grep: `new Map.*index|new Map.*lookup|indexCache|buildIndex`

**Custom transaction management** — wrapping database transactions with application-level retry/rollback logic that duplicates DB transaction semantics:

```typescript
class TransactionManager {
  async begin() { ... }
  async commit() { ... }
  async rollback() { ... }
}
```

Grep: `class\s+\w*Transaction\w*Manager`, `class\s+\w*TransactionWrapper`, manual `BEGIN.*COMMIT.*ROLLBACK` sequences outside of DB driver calls.

**Custom locking** — application-level mutex/semaphore for database row access instead of `SELECT FOR UPDATE` or advisory locks:

```typescript
const lockMap = new Map<string, Promise<void>>();
async function acquireLock(key: string) { ... }
```

Grep: `acquireLock|releaseLock|lockMap|rowLock` (not DB-level `FOR UPDATE`)

### ORM-specific patterns

**Prisma** — reimplementing `$transaction` with manual rollback.
**TypeORM** — custom `QueryRunner` wrapper that duplicates `EntityManager.transaction()`.
**SQLAlchemy** — manual session management bypassing `session.begin()`.

### False positive guidance

- Legitimate uses: connection pooling wrappers, distributed transaction coordinators (Saga pattern), database-agnostic abstraction layers in multi-DB systems.
- Query builders that add domain-specific validation on top of an ORM are not antipatterns.
- If the custom code adds genuinely new behavior (e.g., cross-database joins), it is not inner-platform.

## EAV Abuse

Entity-Attribute-Value schema used where a relational model with typed columns would be clearer and more performant.

### SQL detection

```sql
CREATE TABLE attributes (
  entity_id   INT,
  attribute_name  VARCHAR(255),
  attribute_value TEXT        -- all values stored as text
);
```

Grep patterns:

- `entity_id.*attribute_name.*attribute_value`
- `entity_id.*key.*value` (column triples in CREATE TABLE)
- `attr_name.*attr_value|property_name.*property_value`
- Tables named `*_attributes`, `*_properties`, `*_metadata`, `*_settings` with the EAV triple

### ORM detection

**Prisma**:

```prisma
model Attribute {
  entityId       Int
  attributeName  String
  attributeValue String
}
```

**TypeORM**:

```typescript
@Entity()
export class Attribute {
  @Column() entityId: number;
  @Column() attributeName: string;
  @Column() attributeValue: string; // everything is string
}
```

**SQLAlchemy**:

```python
class Attribute(Base):
    entity_id = Column(Integer, ForeignKey('entities.id'))
    attribute_name = Column(String)
    attribute_value = Column(String)  # no type safety
```

**ActiveRecord**:

```ruby
create_table :attributes do |t|
  t.references :entity
  t.string :name
  t.text :value
end
```

### When EAV is acceptable

- User-defined custom fields where the schema is genuinely unknown at design time
- Plugin/extension systems that must store arbitrary key-value pairs
- Fewer than 5 attributes that change frequently and are never queried with WHERE

Flag as EAV Abuse when:

- The attributes are known at design time and stable
- Queries filter or join on attribute values (performance penalty)
- More than 5 attributes could be typed columns
- Values require type casting in application code

## N+1 Query

Fetching a list of records, then issuing a separate query for each item instead of using a batch query or join.

### Detection patterns

**Loop with query inside** — the primary signal:

```typescript
// TypeScript/JavaScript
const users = await db.user.findMany();
for (const user of users) {
  const orders = await db.order.findMany({ where: { userId: user.id } });
}
```

Grep patterns:

- `for\s*\(.*\)\s*\{[^}]*await\s+\w+\.(find|query|select|get|fetch|load)`
- `\.forEach\(\s*async` followed by a query call
- `\.map\(\s*async` followed by a query call
- `Promise\.all\(\s*\w+\.map\(` with individual queries (batched N+1)

**Python**:

```python
users = User.query.all()
for user in users:
    orders = Order.query.filter_by(user_id=user.id).all()
```

Grep: `for\s+\w+\s+in\s+.*:\s*\n\s+.*\.query\.|for\s+\w+\s+in\s+.*:\s*\n\s+.*\.filter`

**Ruby/ActiveRecord**:

```ruby
User.all.each do |user|
  user.orders  # lazy load triggers N queries
end
```

Grep: `\.all\.each|\.each\s+do.*\n.*\.\w+` (model access inside loop)

### ORM-specific missing eager loading

| ORM          | Eager load syntax                                   | Missing indicator                                                               |
| ------------ | --------------------------------------------------- | ------------------------------------------------------------------------------- |
| Prisma       | `include: { relation: true }`                       | `findMany()` without `include` followed by loop with nested `findMany`          |
| TypeORM      | `relations: ['relation']` or `.leftJoinAndSelect()` | `find()` without `relations` followed by loop access                            |
| Sequelize    | `include: [Model]`                                  | `findAll()` without `include` followed by loop query                            |
| SQLAlchemy   | `joinedload()`, `subqueryload()`                    | `.all()` without eager load options followed by loop attribute access           |
| ActiveRecord | `.includes(:relation)`                              | `.all` or `.where` without `.includes` followed by `.each` with relation access |

### False positive guidance

- Queries inside loops where the loop has a fixed small upper bound (e.g., max 3 iterations by design) are low severity.
- `Promise.all` with `.map` is still N+1 (parallel but still N queries). Flag as warning, not critical.
- Background jobs processing one item at a time by design (queue consumer) are not N+1.
- If the loop body has conditional logic that skips most queries, reduce severity.

## Thresholds summary

| Antipattern           | Info                                  | Warning                             | Critical                                         |
| --------------------- | ------------------------------------- | ----------------------------------- | ------------------------------------------------ |
| God Table             | 15-20 columns with >50% nullable      | 20-40 columns                       | >40 columns                                      |
| Inner-Platform Effect | Query builder with some justification | Partial DB feature reimplementation | Full custom query language or transaction system |
| EAV Abuse             | <5 attributes, rarely queried         | 5-10 typed attributes stored as EAV | >10 attributes, filtered/joined on values        |
| N+1 Query             | Loop with bounded iteration (<5)      | Background job or non-critical path | Request handler or hot path                      |
