# Antipattern Detection Reference

Detailed detection strategies, thresholds, false positive guidance, and severity classification for each antipattern.

## Table of contents

- [1. God Object](#1-god-object)
- [2. Spaghetti Code](#2-spaghetti-code)
- [3. Lava Flow](#3-lava-flow)
- [4. Boat Anchor](#4-boat-anchor)
- [5. Copy-Paste Programming](#5-copy-paste-programming)
- [6. Magic Numbers/Strings](#6-magic-numbersstrings)
- [7. Primitive Obsession](#7-primitive-obsession)
- [8. Poltergeist](#8-poltergeist)
- [9. Circular Dependency](#9-circular-dependency)
- [10. Golden Hammer](#10-golden-hammer)
- [Severity classification summary](#severity-classification-summary)

## 1. God Object

### Detection

- **Glob pattern:** `**/*.{ts,tsx,js,jsx,py,go,rs,java}`
- **Step 1:** Identify files exceeding 500 lines (use `wc -l` or count lines via Read).
- **Step 2:** For each candidate, count exported symbols:
  - TypeScript/JS: Grep for `export (function|const|class|interface|type|enum)` and `public` methods within classes.
  - Python: Count top-level `def` and `class` definitions.
  - Go: Count capitalized function/type names (exported by convention).
- **Threshold:** >500 lines AND >15 exported symbols.

### Severity

- **Critical:** >1000 lines AND >25 exports.
- **Warning:** >500 lines AND >15 exports.

### False positives

- **Generated files** — files with `@generated`, `AUTO-GENERATED`, or `DO NOT EDIT` headers. Skip these.
- **Barrel files** (index.ts re-exports) — high export count is intentional. Skip files that contain only re-exports.
- **Test files** — large test suites are acceptable. Skip `*.test.*`, `*.spec.*`.
- **Type declaration files** (`*.d.ts`) — many exports is normal for type definitions.

## 2. Spaghetti Code

### Detection

- **Step 1:** Parse function boundaries. Grep for function declarations and count lines to the matching closing brace.
  - TypeScript/JS: `function \w+`, `=> {`, `\w+\(.*\) {`
  - Python: `def \w+` — measure to next `def` or `class` at same indentation level.
- **Step 2:** For functions >80 lines, flag as spaghetti.
- **Step 3:** Count nesting depth by tracking indentation increases within conditionals/loops:
  - Grep for `if`, `else`, `for`, `while`, `switch`, `try`, `catch` and measure indentation.
  - Flag nesting depth >4.

### Severity

- **Critical:** Function >150 lines OR nesting >6.
- **Warning:** Function >80 lines OR nesting >4.

### False positives

- **Switch statements** with many cases — high line count but each case is small. Check if individual cases are <10 lines.
- **Configuration objects** — large object literals are not spaghetti. Skip if function body is primarily object/array construction.
- **State machines** — nested switches for state transitions are sometimes acceptable if well-commented.

## 3. Lava Flow

### Detection

- **Grep patterns:**
  - `TODO` — especially `TODO.*remove`, `TODO.*delete`, `TODO.*clean`
  - `FIXME`
  - `HACK`
  - `XXX`
  - `DEPRECATED` (in code, not JSDoc `@deprecated`)
- **Commented-out code detection:**
  - Grep for 3+ consecutive lines starting with `//` or `#`.
  - Within those blocks, look for code-like syntax: `=`, `(`, `)`, `import`, `require`, `function`, `return`, `if`, `for`.
  - Exclude license headers, documentation blocks, and section separators.
- **Age check:** Use `git blame` on flagged lines. TODOs older than 6 months are higher severity.

### Severity

- **Warning:** Active `FIXME`, `HACK`, `XXX` markers.
- **Warning:** Commented-out code blocks (3+ lines).
- **Info:** `TODO` markers without urgency keywords.

### False positives

- **Documentation comments** (`/** */`, `"""`, `'''`) are not commented-out code.
- **Example code in comments** — comments showing usage examples are intentional.
- **Disabled tests** (`xit`, `xdescribe`, `@skip`) — flag separately if desired but do not count as lava flow.

## 4. Boat Anchor

### Detection

- **Step 1:** Grep for all exported symbols:

  ```
  export (function|const|let|class|interface|type|enum) (\w+)
  ```

- **Step 2:** For each exported symbol, search the entire project for imports:

  ```
  import.*{symbol}|from.*{module}
  ```

- **Step 3:** Flag exports with zero external consumers.
- **Additional checks:**
  - Feature flags: Grep for `FEATURE_`, `FF_`, `ENABLE_` prefixes in env files or config. Check if the feature is actually used.
  - Speculative abstractions: interfaces/abstract classes with only one implementation and no tests referencing the interface directly.

### Severity

- **Warning:** Unused exports in non-entry-point files.
- **Info:** Single-implementation interfaces (may be intentional for dependency injection).

### False positives

- **Entry points** — `main`, `index`, `app` files export for external consumers. Skip these.
- **Library public API** — if the project is a library, root exports are for consumers outside the repo.
- **Framework conventions** — some frameworks require specific exports (Next.js `getServerSideProps`, etc.).
- **Dynamic imports** — `import()` expressions may reference symbols not caught by static grep. Check for dynamic import patterns.

## 5. Copy-Paste Programming

### Detection

- **Strategy:** Extract 5+ line blocks from each file and search for matches in other files.
- **Step 1:** Read files and identify distinctive code blocks (skip blank lines, comments, imports).
- **Step 2:** For each block of 5+ non-trivial lines, Grep for the first and last line across the project.
- **Step 3:** If both lines match in another file, Read that file to confirm the full block matches.
- **Threshold:** 5+ consecutive lines with >80% similarity (allowing variable name differences).

### Severity

- **Critical:** 10+ identical lines in 3+ files.
- **Warning:** 5-9 identical lines in 2+ files.

### False positives

- **Generated code** — skip files with generation markers.
- **Boilerplate** — framework-required patterns (React component lifecycle, Express route setup) repeat by design. Apply a higher threshold (10+ lines) for known boilerplate patterns.
- **Test setup** — `beforeEach`/`afterEach` blocks often repeat legitimately. Skip test files or raise the threshold.
- **Import blocks** — similar import patterns are not copy-paste.

## 6. Magic Numbers/Strings

### Detection

- **Grep patterns for numbers:**
  - Numeric literals in conditionals: `if.*[^a-zA-Z_]\d{2,}[^a-zA-Z_]`
  - Comparisons: `[><=!]+\s*\d{2,}`
  - Array access with non-obvious indices: `\[\d{2,}\]`
  - Assignments to non-const variables: `let.*=.*\d{3,}`
- **Grep patterns for strings:**
  - String literals in conditionals: `if.*===?\s*['"]`
  - Repeated identical string literals across 3+ locations
- **Exclusions:**
  - Values 0, 1, -1 (universally understood)
  - Named constants: `const \w+ = \d+`
  - Enum values
  - Test files (test data is acceptable)
  - CSS/style values (pixel counts, colors)
  - HTTP status codes in response handlers (200, 404, 500 — debatable, flag as info)

### Severity

- **Warning:** Numeric literals >1 in business logic conditionals.
- **Warning:** Repeated string literals in 3+ locations.
- **Info:** HTTP status codes, timeout values.

### False positives

- **Mathematical constants** — `Math.PI`, known formulas.
- **Array destructuring** — `[0]`, `[1]` for tuple-like access.
- **Date/time** — `24`, `60`, `365` in date calculations (flag as info, not warning).
- **Port numbers** — `3000`, `8080` in configuration files.

## 7. Primitive Obsession

### Detection

- **Step 1:** Grep for function signatures with 3+ primitive parameters:

  ```
  function \w+\(.*string.*string.*string|number.*number.*number
  ```

- **Step 2:** Look for repeated parameter groups — the same set of primitives passed together in 3+ functions suggests a missing domain type.
- **Step 3:** Check for string parameters used as identifiers (userId, orderId, etc.) — these are candidates for branded types or newtypes.

### Severity

- **Info:** 3+ primitive params in a function signature.
- **Warning:** Same group of primitives repeated in 4+ function signatures.

### False positives

- **Utility functions** — `substring(str, start, end)` legitimately takes primitives.
- **Math/algorithm functions** — numeric parameters are expected.
- **Test helpers** — parameterized test data uses primitives by design.
- **CLI argument parsing** — string parameters from user input.

## 8. Poltergeist

### Detection

- **Step 1:** Find classes with 1-2 methods (excluding constructor):

  ```
  class \w+
  ```

  Read the class body and count method definitions.
- **Step 2:** For each method body, check if it only calls another object's method:

  ```
  return this.\w+.\w+(
  ```

  or

  ```
  return \w+.\w+(
  ```

- **Step 3:** Flag if ALL methods in the class are pure delegation.

### Severity

- **Warning:** Class with only delegation methods and no additional logic.

### False positives

- **Adapter pattern** — intentional wrapping for interface compatibility. Check if the class implements a different interface than the delegate.
- **Decorator pattern** — adds behavior before/after delegation. Check for statements before/after the delegated call.
- **Dependency injection** — classes that exist to make dependencies injectable are valid.
- **Abstract base classes** — template method pattern uses delegation intentionally.

## 9. Circular Dependency

### Detection

- **Step 1:** Build import graph. For each file, Grep for:
  - TypeScript/JS: `import .* from ['"](.*)['"]` and `require\(['"](.*)['"]`
  - Python: `from (\w+) import` and `import (\w+)`
- **Step 2:** Resolve relative paths to absolute paths.
- **Step 3:** Walk the graph using depth-first search. Track the visit stack. If a node is visited while already on the stack, a cycle exists.
- **Step 4:** Report the full cycle chain: `A -> B -> C -> A`.

### Severity

- **Critical:** Direct cycles (A -> B -> A).
- **Warning:** Indirect cycles (3+ nodes in the chain).

### False positives

- **Type-only imports** — `import type { X } from` does not create a runtime cycle in TypeScript. Skip these.
- **Test file imports** — tests importing the module under test do not count.
- **Dynamic imports** — `import()` expressions break the cycle at runtime. Flag as info.
- **Barrel re-exports** — index files may appear in cycles but are often just re-exporting.

## 10. Golden Hammer

### Detection

- **Step 1:** Count usage of specific patterns/utilities across the project:
  - Same utility function called >20 times
  - Same class instantiated in >10 files
  - Same design pattern (Observable, Singleton, Factory) applied uniformly
- **Step 2:** Evaluate whether simpler alternatives exist for specific usage sites:
  - Observable used for single-value state (a simple variable suffices)
  - Factory for classes with no variants (direct construction suffices)
  - Singleton where dependency injection is available

### Severity

- **Info:** All Golden Hammer findings are informational — they require human judgment.

### False positives

- **Standard library usage** — high usage of `Array.map`, `Promise.all` is not a golden hammer.
- **Framework patterns** — React hooks, Express middleware are meant to be used uniformly.
- **Logging/error handling** — a single logging utility used everywhere is correct practice.

## Severity classification summary

| Level    | Meaning                                                                             | Action                              |
| -------- | ----------------------------------------------------------------------------------- | ----------------------------------- |
| Critical | Active code quality risk. Hinders readability, testability, or maintainability now. | Fix before next release.            |
| Warning  | Potential issue. May cause problems as the codebase grows.                          | Plan to address in upcoming sprint. |
| Info     | Observation. May be intentional or acceptable in context.                           | Review and decide.                  |
