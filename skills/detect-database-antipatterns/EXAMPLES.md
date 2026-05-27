# Examples

Detected issues and report output samples for the database antipattern detector.

## Table of contents

- [Example 1: E-commerce application with God Table and N+1](#example-1-e-commerce-application-with-god-table-and-n1)
<!-- markdownlint-disable-next-line MD051 -->
- [Example 2: SaaS platform with EAV Abuse and Inner-Platform Effect](#example-2-saas-platform-with-eav-abuse-and-inner-platform-effect)
- [Example 3: Clean scan with minor findings](#example-3-clean-scan-with-minor-findings)

## Example 1: E-commerce application with God Table and N+1

### Input files

**`migrations/20240115_create_products.sql`**

```sql
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2),
  cost DECIMAL(10,2),
  sku VARCHAR(100),
  barcode VARCHAR(100),
  weight DECIMAL(8,2),
  height DECIMAL(8,2),
  width DECIMAL(8,2),
  depth DECIMAL(8,2),
  color VARCHAR(50),
  size VARCHAR(50),
  material VARCHAR(100),
  brand VARCHAR(100),
  category_id INT,
  subcategory_id INT,
  supplier_id INT,
  warehouse_id INT,
  shelf_location VARCHAR(50),
  reorder_point INT,
  reorder_quantity INT,
  lead_time_days INT,
  tax_rate DECIMAL(5,2),
  discount_rate DECIMAL(5,2),
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  is_digital BOOLEAN DEFAULT false,
  data TEXT,
  field1 VARCHAR(255),
  field2 VARCHAR(255),
  notes TEXT,
  metadata JSONB,
  extra TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**`src/repositories/order-repository.ts`**

```typescript
async getOrdersWithItems(userId: string) {
  const orders = await this.db.order.findMany({
    where: { userId },
  });

  for (const order of orders) {
    order.items = await this.db.orderItem.findMany({
      where: { orderId: order.id },
    });
    order.shipping = await this.db.shipping.findFirst({
      where: { orderId: order.id },
    });
  }

  return orders;
}
```

### Report output

````
# Database Antipattern Report

**Scanned:** 14 files
**Database files found:** 3 migrations, 5 models, 6 query files
**Findings:** 2 critical, 1 warning, 0 info

## Critical
- [God Table] migrations/20240115_create_products.sql:1 — Table `products` has 36 columns including generic names (`data`, `field1`, `field2`, `extra`, `metadata`). Consider extracting: product_dimensions, product_inventory, product_categorization.
- [N+1 Query] src/repositories/order-repository.ts:4 — Loop over `orders` issues 2 queries per iteration (`orderItem.findMany`, `shipping.findFirst`). For 100 orders this produces 201 queries instead of 3.

## Warnings
(none)

## Info
(none)

## Recommendations
1. **[God Table] Split `products` table** — Extract dimension columns (weight, height, width, depth) into `product_dimensions`. Move inventory columns (reorder_point, reorder_quantity, lead_time_days, warehouse_id, shelf_location) into `product_inventory`. Remove generic columns (`data`, `field1`, `field2`, `extra`) or give them domain-specific names.
2. **[N+1 Query] Use eager loading** — Replace the loop with a single query using `include`:
   ```typescript
   const orders = await this.db.order.findMany({
     where: { userId },
     include: { items: true, shipping: true },
   });
````

````

## Example 2: SaaS platform with EAV Abuse and Inner-Platform Effect

### Input files

**`prisma/schema.prisma`**
```prisma
model TenantSetting {
  id          Int    @id @default(autoincrement())
  tenantId    Int
  settingName String
  settingValue String
  tenant      Tenant @relation(fields: [tenantId], references: [id])

  @@index([tenantId, settingName])
}
````

**`src/lib/query-engine.ts`**

```typescript
export class DynamicQueryEngine {
  private filters: Filter[] = [];
  private sorts: Sort[] = [];
  private joins: JoinClause[] = [];
  private indexHints: Map<string, string[]> = new Map();

  where(field: string, operator: string, value: unknown): this {
    this.filters.push({ field, operator, value });
    return this;
  }

  join(table: string, on: string, type: 'INNER' | 'LEFT' = 'INNER'): this {
    this.joins.push({ table, on, type });
    return this;
  }

  useIndex(table: string, indexName: string): this {
    const hints = this.indexHints.get(table) || [];
    hints.push(indexName);
    this.indexHints.set(table, hints);
    return this;
  }

  compile(): { sql: string; params: unknown[] } {
    // Builds raw SQL from accumulated clauses
    let sql = `SELECT * FROM ${this.baseTable}`;
    // ... 200 lines of SQL string construction
  }
}
```

### Example 2 report output

```
# Database Antipattern Report

**Scanned:** 22 files
**Database files found:** 1 migration, 8 models, 4 query files
**Findings:** 1 critical, 2 warnings, 0 info

## Critical
- [Inner-Platform Effect] src/lib/query-engine.ts:1 — `DynamicQueryEngine` reimplements SQL query building with custom join, filter, and index hint systems. This duplicates Prisma's query API and introduces SQL injection risk in `compile()`.

## Warnings
- [EAV Abuse] prisma/schema.prisma:1 — `TenantSetting` uses EAV pattern (`settingName`/`settingValue` as strings). If settings are known at design time (e.g., theme, timezone, locale), use typed columns instead.
- [Inner-Platform Effect] src/lib/query-engine.ts:20 — `useIndex()` method implements application-level index hinting. Database query planners handle index selection; manual hints bypass optimizer improvements.

## Info
(none)

## Recommendations
1. **[Inner-Platform Effect] Remove `DynamicQueryEngine`** — Replace with Prisma's built-in query API. If dynamic filtering is needed, use Prisma's `where` object construction. The `compile()` method risks SQL injection by concatenating strings.
2. **[EAV Abuse] Convert `TenantSetting` to typed columns** — If the settings are enumerable (theme, timezone, locale, language, notifications_enabled), add them as typed columns on the `Tenant` model directly. Reserve EAV only for truly user-defined custom fields.
```

## Example 3: Clean scan with minor findings

### Input files

A well-structured application using Prisma with proper eager loading and normalized schema.

**`src/services/user-service.ts`**

```typescript
async getUserDashboard(userId: string) {
  return this.db.user.findUnique({
    where: { id: userId },
    include: {
      orders: { take: 10, orderBy: { createdAt: 'desc' } },
      notifications: { where: { read: false } },
      profile: true,
    },
  });
}
```

### Example 3 report output

```
# Database Antipattern Report

**Scanned:** 18 files
**Database files found:** 5 migrations, 6 models, 7 query files
**Findings:** 0 critical, 0 warnings, 1 info

## Critical
(none)

## Warnings
(none)

## Info
- [God Table] prisma/schema.prisma:45 — Model `AuditLog` has 18 columns with 12 nullable. Column count is below threshold but nullable ratio is high (67%). Consider whether all fields belong in the audit context.

## Recommendations
1. **[God Table] Review `AuditLog` nullable columns** — High nullable ratio often indicates optional fields from different event types. Consider using a discriminated union pattern: a base `AuditLog` table with type-specific detail tables, or a typed JSONB `details` column with a documented schema per event type.
```
