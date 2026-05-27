# Pattern Detection Reference

## Table of contents

- [Detection heuristics](#detection-heuristics) — Signal indicators per pattern category
- [Scoring methodology](#scoring-methodology) — Signal strength, effort, and impact scales
- [Anti-pattern checklist](#anti-pattern-checklist-for-audit-mode) — Common misapplications per pattern

## Detection heuristics

For each pattern category, use these signal indicators when scanning the codebase. A "strong signal" requires matching 2+ indicators from the "use when" column.

### Creational patterns

| Pattern          | Signal Indicators                                                                                   | Grep/Glob Targets                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Singleton        | Global shared resource (config, logger, pool); module-level instance export; `getInstance()` method | `getInstance`, `export const.*= new`, `private constructor`             |
| Factory Method   | Abstract class with creation method; subclasses return different product types; `create*()` methods | `abstract.*create`, `factory`, `create.*():`                            |
| Abstract Factory | Multiple families of related objects; theme/platform switching; coordinated object sets             | `Factory`, `Theme`, `Provider`, interface families                      |
| Builder          | Complex object with many optional params; fluent API chains; telescoping constructors (>4 params)   | `.set*().set*()`, `build()`, `Builder`, constructors with >4 parameters |
| Prototype        | Expensive object creation; `clone()` methods; deep copy utilities                                   | `clone()`, `structuredClone`, `JSON.parse(JSON.stringify`               |

### Structural patterns

| Pattern   | Signal Indicators                                                              | Grep/Glob Targets                                                                 |
| --------- | ------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| Adapter   | Wrapper translating one interface to another; third-party integration wrappers | `Adapter`, `Wrapper`, classes implementing interface X that wrap class Y          |
| Bridge    | Two independent dimensions of variation (abstraction x implementation)         | Abstraction holding Implementor reference; dual hierarchies                       |
| Composite | Tree structures; parent-child with uniform `interface` for leaves and nodes    | `children`, `add(child)`, recursive `getSize/render/process`                      |
| Decorator | Wrapper implementing same interface as wrapped; additive behavior              | Class wrapping same-interface instance; `Logging*`, `Caching*`, `Retry*` prefixes |
| Facade    | Single class delegating to multiple subsystem classes                          | Class with methods calling 3+ different internal services                         |
| Flyweight | Large number of similar objects; shared intrinsic state pool                   | `WeakMap`, `Map` as object cache; factory returning cached instances              |
| Proxy     | Lazy loading, access control, caching around another object                    | `Proxy`, `lazy`, class wrapping real subject with same interface                  |

### Behavioral patterns

| Pattern                 | Signal Indicators                                                           | Grep/Glob Targets                                                         |
| ----------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| Observer                | Event subscription; pub/sub; `on/off/emit` patterns                         | `addEventListener`, `subscribe`, `emit`, `notify`, `EventEmitter`         |
| Strategy                | Interchangeable algorithms; switch/case on type selecting behavior          | `Strategy`, function parameter for algorithm, switch selecting behavior   |
| Command                 | Request objects with `execute()`; undo support; command queue               | `execute()`, `Command`, `undo()`, `invoke()`, command registry            |
| State                   | Behavior changes with internal state; large state-dependent conditionals    | `State`, `setState`, `status`-dependent switch blocks, state machines     |
| Template Method         | Abstract base with skeleton + hook methods; overridden steps                | `abstract` class with non-abstract orchestrator calling abstract methods  |
| Iterator                | Custom traversal; `next()/hasNext()` protocol; generator functions          | `[Symbol.iterator]`, `next()`, `function*`, custom iterator class         |
| Mediator                | Central coordinator preventing direct communication; many-to-many reduction | `Mediator`, `Hub`, central dispatch, components referencing only mediator |
| Chain of Responsibility | Sequential handlers; middleware; request pipeline with pass-through         | `handle()`, `next()`, middleware arrays, `use()` registration             |
| Visitor                 | Operations on structure elements; `accept(visitor)` / `visit(element)`      | `accept`, `visit`, `Visitor`, double dispatch                             |
| Memento                 | State snapshots; undo stack; checkpoint/restore                             | `save()`, `restore()`, `memento`, `snapshot`, undo history array          |

### Architectural patterns

| Pattern      | Signal Indicators                                                                  | Grep/Glob Targets                                                           |
| ------------ | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Layered      | Horizontal layers (UI → Business → Data); each layer imports only from below       | `controllers/`, `services/`, `models/`, `repositories/` directory structure |
| Hexagonal    | Ports (interfaces) + Adapters (implementations); core never imports infrastructure | `ports/`, `adapters/`, core interfaces with infra implementations           |
| Event-Driven | Event bus; message queues; async event handlers                                    | `EventBus`, `publish`, `subscribe`, `on('event',`                           |
| CQRS         | Separate read/write models or handlers                                             | `Command`, `Query`, separate read/write repositories                        |

### Concurrency patterns

| Pattern                   | Signal Indicators                             | Grep/Glob Targets                                        |
| ------------------------- | --------------------------------------------- | -------------------------------------------------------- |
| Thread Pool / Worker Pool | Worker threads; task queue; pool of executors | `Worker`, `worker_threads`, pool size config, task queue |
| Producer-Consumer         | Shared buffer; async queue; backpressure      | `Queue`, `enqueue`, `dequeue`, bounded buffer            |

### Enterprise patterns

| Pattern         | Signal Indicators                                                   | Grep/Glob Targets                                                             |
| --------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Repository      | Collection-like data access; `find/save/remove` methods             | `Repository`, `find()`, `save()`, `remove()`, `getById()`                     |
| DTO             | Plain data objects crossing boundaries; no methods beyond accessors | `Dto`, `Response`, `Request` suffix types; interface-only types at boundaries |
| Gateway         | External system access wrapper; protocol isolation                  | `Gateway`, `Client`, `Api` classes wrapping HTTP/DB calls                     |
| Circuit Breaker | Failure tracking; fallback on open state; half-open recovery        | `CircuitBreaker`, failure counters, open/closed/half-open states              |

### Functional patterns

| Pattern      | Signal Indicators                                          | Grep/Glob Targets                                   |
| ------------ | ---------------------------------------------------------- | --------------------------------------------------- |
| Monad/Result | Chained error handling; `Option/Maybe/Result/Either` types | `Result<`, `Option<`, `flatMap`, `chain`, `andThen` |
| Functor      | `.map()` on custom containers beyond arrays                | Custom `.map()` implementations on non-Array types  |

### DDD patterns

| Pattern      | Signal Indicators                                        | Grep/Glob Targets                                               |
| ------------ | -------------------------------------------------------- | --------------------------------------------------------------- |
| Value Object | Immutable types defined by attributes; equality by value | `readonly` fields, no ID field, custom `equals()` by fields     |
| Entity       | Objects with unique ID; identity-based equality          | `id` field, `equals` comparing IDs, tracked lifecycle           |
| Aggregate    | Cluster of entities with root; transactional boundary    | `AggregateRoot`, nested entities, invariant enforcement methods |

## Scoring methodology

### Signal strength scale

| Level        | Criteria                                                                                                                                                 |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Strong**   | 2+ "use when" criteria match AND concrete code locations identified AND pattern improves measurable quality (testability, extensibility, or readability) |
| **Moderate** | 1 "use when" criterion matches OR opportunity exists but current code works acceptably                                                                   |
| **Weak**     | Theoretical applicability but no concrete benefit at current scale                                                                                       |
| **None**     | Pattern prerequisites absent (e.g., concurrency patterns in single-threaded code)                                                                        |

### Effort estimation

| Level      | Definition                                                                   |
| ---------- | ---------------------------------------------------------------------------- |
| **Low**    | Single file change; no new interfaces; <50 lines modified                    |
| **Medium** | 2-5 files; new interface or class; 50-200 lines; existing tests need updates |
| **High**   | 5+ files; architectural change; 200+ lines; new test coverage required       |

### Impact categories

- **Testability** — Enables unit testing without mocks/stubs; decouples dependencies
- **Extensibility** — New functionality via addition, not modification (Open-Closed)
- **Readability** — Reduces cognitive load; eliminates complex conditionals
- **Maintainability** — Reduces coupling; clarifies responsibilities

## Anti-pattern checklist (for audit mode)

| Anti-Pattern                      | Description                                                   | Common in               |
| --------------------------------- | ------------------------------------------------------------- | ----------------------- |
| God Object Singleton              | Singleton accumulating unrelated responsibilities             | Singleton               |
| Factory Explosion                 | Too many factory methods when simple construction suffices    | Factory Method          |
| Over-Decorated                    | 5+ nested decorators making debugging impossible              | Decorator               |
| Leaky Facade                      | Facade exposing subsystem internals through parameters        | Facade                  |
| Anemic Strategy                   | Strategy interface with only one implementation               | Strategy                |
| State Machine Without Transitions | State pattern without explicit valid transition rules         | State                   |
| Observer Memory Leak              | Subscribers never unregistered                                | Observer                |
| Chain Without Terminator          | Chain of Responsibility where requests fall through unhandled | Chain of Responsibility |
