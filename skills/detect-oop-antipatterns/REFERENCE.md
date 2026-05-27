# OOP Antipattern Detector -- Reference

Detailed detection heuristics, thresholds, false positive guidance, and language-specific notes for each antipattern.

## Table of contents

- [1. Anemic Domain Model](#1-anemic-domain-model)
- [2. God Class / Blob](#2-god-class--blob)
- [3. Yo-Yo Problem](#3-yo-yo-problem)
- [4. Refused Bequest](#4-refused-bequest)
- [5. Feature Envy](#5-feature-envy)
- [6. Inappropriate Intimacy](#6-inappropriate-intimacy)

## 1. Anemic Domain Model

**What it is:** Data-holding classes with no behavior. Business logic lives in separate `*Service` or `*Manager` classes that manipulate the model's fields.

### Detection patterns

- **Grep for model classes:** `class \w+(Model|Entity|DTO)` or classes where every method is a getter/setter (methods matching `get\w+|set\w+|is\w+`).
- **Grep for companion services:** `class \w+Service` or `class \w+Manager` that import or reference the model class.
- **Threshold:** A class qualifies as anemic if it has 3+ fields and 0 business methods (methods beyond getters/setters/constructors).

### Language-specific patterns

| Language      | Getter/setter pattern                                              | Notes                                                                                         |
| ------------- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| TypeScript/JS | `get \w+()`, `set \w+()`, property assignments in constructor only | Watch for classes using `readonly` fields with no methods                                     |
| Python        | `@property`, `__init__` with only `self.x = x`                     | Dataclasses (`@dataclass`) are anemic by design -- flag only if a matching service exists     |
| Java          | `getX()`, `setX()`, `isX()` patterns                               | Lombok `@Data` / `@Getter` / `@Setter` classes are common -- flag only with companion service |

### False positives

- **DTOs / Value Objects:** Classes explicitly named `*DTO`, `*VO`, `*Request`, `*Response` are intentionally anemic. Exclude them.
- **Config classes:** Classes named `*Config`, `*Options`, `*Settings` are data holders by design.
- **Event classes:** `*Event`, `*Message` are transport objects. Exclude.

### Threshold justification

The 0-business-methods threshold catches genuine anemic models while the DTO/VO exclusion list prevents noise. The companion service check confirms the antipattern -- an anemic class without a service manipulating it is just a data structure.

---

## 2. God Class / Blob

**What it is:** A single class that has grown to handle too many responsibilities.

### Detection patterns

- **Method count:** Count method definitions within a class body. Threshold: >30 methods.
- **Line count:** Count lines from class opening brace to closing brace. Threshold: >500 lines.
- **Import count:** Count unique import statements at file top. Threshold: >10 imports from distinct modules.
- **Grep patterns:**
  - TS/JS: Count occurrences of `\b(async\s+)?\w+\s*\(` inside class body
  - Python: Count `def \w+\(self` within class indent
  - Java: Count `(public|private|protected)\s+\w+\s+\w+\s*\(`

### False positives

- **Test classes:** Classes named `*Test`, `*Spec`, `*Suite` often have many methods (one per test case). Exclude or raise threshold to >60.
- **Generated code:** Files with `// @generated` or `# AUTO-GENERATED` headers. Exclude entirely.
- **Facade classes:** A class that delegates to many smaller classes may have many short methods. Check if methods are 1-3 lines of delegation -- if so, downgrade to info.

### Threshold justification

30 methods aligns with empirical studies (Lanza & Marinescu, "Object-Oriented Metrics in Practice") for the boundary where classes become hard to understand. 500 lines is a conservative file-level marker. 10 imports indicates coupling to many modules.

---

## 3. Yo-Yo Problem

**What it is:** Deep inheritance chains that force developers to bounce up and down the hierarchy to understand behavior.

### Detection patterns

- **Trace `extends` chains:** For each class with `extends`, follow the chain to the root. Count depth.
- **Threshold:** Depth >3 is a warning. Depth >5 is critical.
- **Grep pattern:** `class\s+\w+\s+extends\s+(\w+)` -- extract parent class name, then search for that parent's definition and repeat.

### Language-specific notes

| Language      | Syntax              | Notes                                                                                                  |
| ------------- | ------------------- | ------------------------------------------------------------------------------------------------------ |
| TypeScript/JS | `class X extends Y` | Also check `implements` for interface chains, but do not count interface depth toward this antipattern |
| Python        | `class X(Y):`       | Multiple inheritance counts the deepest single chain, not breadth                                      |
| Java          | `class X extends Y` | Abstract classes in the chain still count toward depth                                                 |

### False positives

- **Framework base classes:** Chains like `Component > PureComponent > React.Component` are framework-imposed. If the first 1-2 levels are from `node_modules` or standard library, subtract them from the count.
- **AST / Visitor patterns:** Compiler projects legitimately use deep hierarchies. Flag at info level with a note.

### Threshold justification

Research (Gamma et al., "Design Patterns") recommends favoring composition over inheritance. Depth >3 makes the mental model difficult; >5 makes it nearly impossible to reason about method resolution order.

---

## 4. Refused Bequest

**What it is:** A subclass inherits from a parent but throws away or ignores inherited behavior.

### Detection patterns

- **Grep for override + throw:** Methods that override a parent method and contain `throw new`, `raise NotImplementedError`, `throw new UnsupportedOperationException`.
- **Grep for empty overrides:** Methods whose body is `{}`, `pass`, `return`, `return undefined`, `return null`, or contains only a comment like `// not used`, `// not implemented`, `# noop`.
- **Grep patterns:**
  - TS/JS: `override\s+\w+.*\{[\s]*(throw|return;|return undefined|return null|\/\/\s*(not|no))` (multiline)
  - Python: `def \w+\(self.*\):\s*(pass|raise NotImplementedError)`
  - Java: `@Override[\s\S]*?(throw new UnsupportedOperationException|return null;|\{\s*\})`

### False positives

- **Template Method pattern:** Abstract classes that define hooks as empty methods for subclasses to optionally override. Check if the parent method is explicitly documented as optional (e.g., `// optional hook`).
- **Lifecycle methods:** Framework lifecycle methods (`componentDidMount`, `setUp`, `tearDown`) that are legitimately empty in some subclasses.
- **Interface adapters:** Classes implementing an interface where not all methods apply. This is a design smell but may be intentional -- downgrade to info.

### Threshold justification

Any single refused bequest is a warning because it indicates a Liskov Substitution Principle violation. Multiple (3+) in the same class escalate to critical -- the class likely should not inherit from that parent.

---

## 5. Feature Envy

**What it is:** A method that uses another object's data more than its own class's data.

### Detection patterns

- **Count external property accesses:** For each method, count how many times it accesses properties/methods on a single external object (e.g., `other.x`, `other.getY()`, `other.z`).
- **Threshold:** >3 accesses to a single external object within one method.
- **Grep patterns:**
  - Look for repeated patterns like `(\w+)\.\w+` where the same identifier appears >3 times in a method body.
  - TS/JS: `this\.\w+` counts as internal; anything else with a dot accessor is external.
  - Python: `self\.\w+` is internal; other `\w+\.\w+` is external.

### False positives

- **Builder/fluent APIs:** `builder.setX().setY().setZ()` is fluent chaining, not feature envy. Check if the accessed object is the return value of the previous call.
- **Logging:** `logger.info()`, `logger.error()` accesses are utility calls. Exclude objects named `log`, `logger`, `console`.
- **Assertion libraries:** `expect(x).toBe()`, `assert.equal()` in test files. Exclude test files entirely.
- **Dependency injection:** Constructor parameter usage in initialization is not feature envy.

### Threshold justification

3 external accesses is the point where a method likely belongs on the other class. Martin Fowler's "Refactoring" identifies this as the primary indicator for Move Method refactoring.

---

## 6. Inappropriate Intimacy

**What it is:** Classes that know too much about each other's internal structure.

### Detection patterns

- **Deep chain calls:** Expressions with 3+ dots: `a.b.c.d`. This violates the Law of Demeter.
  - Grep: `\w+\.\w+\.\w+\.\w+` (4 identifiers = 3 dots).
- **Private field access from outside:** Accessing fields prefixed with `_` or `#` from outside the owning class.
  - Grep for `_\w+` usage: cross-reference with class definitions to check if the access is external.
  - TS/JS: `#privateField` is enforced by the runtime; `_conventionPrivate` is convention-only.
- **Friend/internal access:** In TypeScript, accessing properties marked `@internal` from outside the package.

### Language-specific notes

| Language   | Private convention             | Runtime enforcement                                          |
| ---------- | ------------------------------ | ------------------------------------------------------------ |
| TypeScript | `private`, `#field`, `_prefix` | `#field` is runtime-enforced; `private` is compile-time only |
| JavaScript | `#field`, `_prefix`            | `#field` is runtime-enforced                                 |
| Python     | `_prefix`, `__mangled`         | Convention only; `__mangled` has name mangling               |
| Java       | `private` keyword              | Runtime-enforced via reflection                              |

### False positives

- **Method chaining on same object:** `array.filter().map().reduce()` returns new objects at each step. Exclude if the chain involves known fluent APIs (arrays, streams, observables, query builders).
- **Optional chaining:** `a?.b?.c?.d` is defensive access, not necessarily inappropriate. Downgrade to info.
- **Test fixtures:** Test setup code accessing internals for test purposes. Exclude test files or downgrade to info.
- **Serialization:** JSON path access like `data.response.body.items` on plain objects (non-class instances) is normal. Only flag when the chain traverses class instances.

### Threshold justification

The Law of Demeter ("only talk to your immediate friends") is violated at 3+ dots. Private field access from outside is always a warning regardless of count, as it creates tight coupling that breaks encapsulation.
