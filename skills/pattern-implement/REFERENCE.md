# Pattern Implementation Reference

## Table of contents

- [Implementation checklists](#implementation-checklists) — Per-category steps and verification points
- [Common pitfalls](#common-pitfalls) — Mistakes that cause pattern implementations to fail
- [Refactoring safety](#refactoring-safety) — How to keep tests green during restructuring

## Implementation checklists

### Creational patterns

**Builder**:

1. Identify the target: constructor with 4+ parameters, or complex object built inline
2. Create a Builder class with fluent setter methods returning `this`
3. Add a `build()` method that returns the constructed object
4. Replace inline construction with builder chain
5. Verify: original tests pass unchanged; add builder-specific tests

**Factory Method**:

1. Identify the creation point to abstract
2. Define a product interface if one does not exist
3. Create abstract creator class with `create(): Product` method
4. Move existing creation logic into a concrete creator
5. Verify: callers use the interface, not concrete types

**Singleton** (use sparingly):

1. Make constructor private
2. Add static `getInstance()` method with lazy initialization
3. Consider thread safety if applicable
4. Verify: no public constructors remain; all access through `getInstance()`

### Structural patterns

**Decorator**:

1. Extract an interface from the target class (the component interface)
2. Create a base decorator class implementing the interface, wrapping the inner component
3. Create concrete decorators adding specific behavior
4. Update callers to accept the interface type, not the concrete class
5. Verify: decorators compose (`new A(new B(new C(real)))` works); original behavior unchanged

**Adapter**:

1. Define the target interface the client expects
2. Create adapter class implementing target interface
3. Adapter wraps the adaptee and translates method calls
4. Replace direct adaptee usage with adapter
5. Verify: client code unchanged; adaptee isolated behind adapter

**Facade**:

1. Identify the subsystem classes clients interact with directly
2. Create a facade class with simplified methods
3. Facade methods delegate to subsystem internals
4. Redirect client code to use the facade
5. Verify: subsystem internals are no longer imported by clients

### Behavioral patterns

**Chain of Responsibility**:

1. Define a handler interface with a `handle(context, result)` method
2. Define a context type carrying shared state across handlers
3. Extract each existing step into a class implementing the handler interface
4. Create a chain runner that iterates handlers sequentially
5. Replace the original orchestration with the chain runner
6. Verify: adding/removing a handler does not require modifying the runner

**Strategy**:

1. Identify the varying algorithm (often a switch/case or if/else chain)
2. Define a strategy interface with the algorithm's signature
3. Create concrete strategy classes, one per case
4. Create a strategy map or factory for lookup
5. Replace the conditional with strategy lookup + invocation
6. Verify: adding a new strategy requires no modification to existing code

**Observer**:

1. Define an event type and observer interface with `update(event)` method
2. Add subscription management to the subject: `subscribe()`, `unsubscribe()`
3. Add `notify()` that iterates observers and calls `update()`
4. Convert existing direct calls to event emission
5. Verify: observers can be added/removed dynamically; no memory leaks

**Template Method**:

1. Identify the shared algorithm skeleton and varying steps
2. Create abstract base class with the skeleton as a concrete method
3. Define abstract methods for varying steps (hooks)
4. Move existing implementations into concrete subclasses overriding hooks
5. Verify: skeleton cannot be overridden (mark as `final` or non-virtual); hooks are the only extension points

**Command**:

1. Define a command interface with `execute()` (and optionally `undo()`)
2. Create concrete command classes, each encapsulating a receiver and action
3. Create an invoker that stores and dispatches commands
4. Replace direct method calls with command dispatch
5. Verify: commands are composable and support undo if required

**State**:

1. Define a state interface with methods matching state-dependent behavior
2. Create concrete state classes implementing each state's behavior
3. Context delegates to the current state object
4. State transitions update the context's state reference
5. Verify: no state-dependent conditionals remain in the context; transitions are explicit

### Enterprise patterns

**Repository**:

1. Define a repository interface with domain-friendly methods (`find`, `save`, `remove`)
2. Move data access logic from callers into the repository implementation
3. Callers use only the repository interface
4. Verify: data store details are isolated; switching stores requires only a new implementation

## Common pitfalls

| Pitfall                                                     | Pattern                 | How to avoid                                                                                                |
| ----------------------------------------------------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------- |
| Interface extracted but only one implementation exists      | Decorator, Strategy     | Defer interface extraction until a second implementation is needed, OR document the planned second use      |
| Builder with required fields not enforced                   | Builder                 | Use a "stepped builder" pattern: `RequiredStep1 -> RequiredStep2 -> OptionalBuilder`                        |
| Decorator that modifies wrapped object state                | Decorator               | Decorators add behavior around calls, not mutate inner state                                                |
| Chain handler that always processes (never skips)           | Chain of Responsibility | Each handler must decide: process OR pass. If all handlers always process, you have a pipeline, not a chain |
| Strategy map returning undefined for unknown keys           | Strategy                | Provide a default/fallback strategy, or throw explicitly                                                    |
| Observer with circular notification                         | Observer                | Track notification depth; prevent re-entrant `notify()` calls                                               |
| Factory creating objects the caller immediately type-checks | Factory Method          | If the caller needs the concrete type, the factory is not adding value                                      |

## Refactoring safety

### Keep tests green at every step

1. **Extract interface first** — no behavior changes, only type additions. Tests pass.
2. **Create new classes alongside old ones** — don't delete yet. Tests pass.
3. **Redirect callers one at a time** — each redirect is independently testable. Tests pass.
4. **Delete old code last** — only after all callers migrated. Tests pass.

### When tests must change

- Tests that construct concrete classes directly may need updating when constructors become private (Singleton) or when interfaces replace concrete types
- Tests that mock by subclass may need updating when interfaces are introduced
- Add these test changes as their own step in the refactoring sequence, not interleaved with production code changes

### Rollback strategy

- Each refactoring step is one commit
- If a step breaks something unexpected, revert just that commit
- Commit message format: `refactor: extract {Interface} from {ConcreteClass}` or `refactor: apply {PatternName} to {Component}`
