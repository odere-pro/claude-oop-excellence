# Testing Antipattern Detection Reference

Detailed detection strategies, grep patterns, thresholds, and false positive guidance for each antipattern.

## Table of contents

- [Ice Cream Cone (Inverted Test Pyramid)](#ice-cream-cone-inverted-test-pyramid)
- [Flaky Tests](#flaky-tests)
- [Testing Implementation Details](#testing-implementation-details)
- [Slow Tests](#slow-tests)

## Ice Cream Cone (Inverted Test Pyramid)

### Detection strategy

Count test files by type and compare ratios. A healthy test pyramid has more unit tests than integration tests, and more integration tests than E2E tests.

### Classification patterns

**Unit test indicators:**

- File path contains `/unit/` or `__tests__/unit/`
- Filename: `*.unit.test.*`, `*.unit.spec.*`
- No imports from: `playwright`, `cypress`, `puppeteer`, `selenium`, `supertest`, `request`
- No database connection setup in `beforeAll`/`beforeEach`

**Integration test indicators:**

- File path contains `/integration/`
- Filename: `*.integration.test.*`, `*.integration.spec.*`
- Imports: `supertest`, `request`, database clients
- Contains `beforeAll` with server/database setup

**E2E test indicators:**

- File path contains `/e2e/`, `/cypress/`, `/playwright/`
- Filename: `*.e2e.test.*`, `*.e2e.spec.*`
- Imports: `playwright`, `cypress`, `puppeteer`, `selenium`, `@testing-library/react` with `render`

### Grep patterns

```
# Count E2E files
rg -l "import.*from.*(playwright|cypress|puppeteer|selenium)" --type ts --type js

# Count integration files
rg -l "import.*from.*(supertest|@nestjs/testing)" --type ts --type js

# Directories
find . -path "*/e2e/*" -name "*.test.*" | wc -l
find . -path "*/unit/*" -name "*.test.*" | wc -l
```

### Thresholds

| Condition                                    | Severity                |
| -------------------------------------------- | ----------------------- |
| E2E count > unit count (ratio > 1:1)         | Critical                |
| E2E count = unit count                       | Warning                 |
| Integration count > unit count               | Warning                 |
| Any test type has 0 files while others exist | Warning (missing layer) |

### False positives

- Component tests using `@testing-library/react` with `render` may look like E2E but are unit tests. Check if they import a browser automation tool vs a test renderer.
- Files in `/e2e/` that only contain test utilities or fixtures, not actual test cases.
- Monorepos where different packages have different pyramids — evaluate per package.

## Flaky Tests

### Detection strategy

Scan for non-deterministic patterns: timing dependencies, shared mutable state, external service calls, random values in assertions.

### Grep patterns

```
# Hardcoded delays
rg "setTimeout\(.*,\s*\d+" --type ts --type js
rg "sleep\(\d+" --type ts --type js
rg "waitFor\(.*timeout:\s*\d+" --type ts --type js
rg "\.pause\(\d+" --type ts --type js

# Random values in test context
rg "Math\.random\(\)" --type ts --type js
rg "Date\.now\(\)" --type ts --type js
rg "new Date\(\)" --type ts --type js

# Shared mutable state
rg "^\s*let\s+\w+\s*[:=]" --type ts --type js  # (within describe blocks)

# External service dependencies
rg "process\.env\.\w+.*URL" --type ts --type js
rg "fetch\(['\"]https?://" --type ts --type js
```

### Thresholds

| Pattern                                                 | Severity                  |
| ------------------------------------------------------- | ------------------------- |
| `setTimeout`/`sleep` with delay > 1000ms                | Critical                  |
| `setTimeout`/`sleep` with delay <= 1000ms               | Warning                   |
| `Math.random()` in test assertions                      | Critical                  |
| `Date.now()` in equality assertions (`toBe`, `toEqual`) | Critical                  |
| `Date.now()` in range assertions (`toBeGreaterThan`)    | Info                      |
| Shared `let` without `beforeEach` reset                 | Warning                   |
| Shared `let` with `beforeEach` reset                    | Info (likely intentional) |
| `fetch`/`axios` to real URLs in unit tests              | Critical                  |

### False positives

- `waitFor` from `@testing-library` with reasonable timeout (under 1s) is standard practice for async component testing. Flag only when timeout exceeds 5000ms.
- `Date.now()` used to measure test execution time (not in assertions) is safe.
- `Math.random()` used in test data generators with seeded values is safe.
- `let` variables that are reassigned in `beforeEach` are proper setup/teardown.
- `setTimeout` in the code under test (not in the test itself) is not a test antipattern.

## Testing Implementation Details

### Detection strategy

Identify tests that assert on internal implementation rather than observable behavior. These tests break on refactoring even when behavior is preserved.

### Grep patterns

```
# Private method access
rg "\.\w+\['.+'\]" --type ts --type js          # bracket notation for private access
rg "as any\)\.(\w+)" --type ts                   # casting to bypass private
rg "// @ts-ignore" --type ts                      # suppressing type errors for private access

# Spy on internals
rg "jest\.spyOn\(.*,\s*'_\w+'" --type ts --type js   # spying on underscore-prefixed methods
rg "vi\.spyOn\(.*,\s*'_\w+'" --type ts --type js     # vitest variant
rg "sinon\.spy\(.*,\s*'_\w+'" --type ts --type js    # sinon variant

# Call order assertions
rg "toHaveBeenCalledBefore" --type ts --type js
rg "toHaveBeenCalledAfter" --type ts --type js
rg "\.mock\.calls\[\d+\]" --type ts --type js     # accessing specific call indices

# Internal state assertions
rg "\.state\." --type ts --type js                 # React internal state
rg "\.instance\(\)" --type ts --type js            # Enzyme instance access
rg "wrapper\.vm\." --type ts --type js             # Vue internal access
```

### Thresholds

| Pattern                                       | Severity |
| --------------------------------------------- | -------- |
| Spying on underscore-prefixed methods         | Critical |
| Casting to `any` to access private members    | Critical |
| `toHaveBeenCalledBefore`/`After`              | Warning  |
| Accessing `.mock.calls` with specific indices | Warning  |
| Enzyme `.instance()` or `.state()`            | Warning  |
| `@ts-ignore` before member access             | Info     |

### False positives

- Spying on public API methods to verify they were called is standard practice.
- `jest.spyOn(console, 'error')` is a common pattern for suppressing expected errors — not an antipattern.
- `.mock.calls` used to verify the number of calls (`.mock.calls.length`) rather than specific arguments at specific indices is acceptable.
- Testing protected methods in abstract base classes may be intentional design.

## Slow Tests

### Detection strategy

Identify patterns that cause unnecessary test execution time: expensive setup, real I/O, missing parallelization.

### Grep patterns

```
# Large setup blocks (check line count manually)
rg "beforeAll\(|beforeEach\(" --type ts --type js

# Unmocked network calls
rg "fetch\(" --type ts --type js
rg "axios\." --type ts --type js
rg "http\.request\(" --type ts --type js
rg "https\.request\(" --type ts --type js

# File I/O in tests
rg "fs\.(read|write|mkdir|unlink|rm)" --type ts --type js
rg "fs\.promises\." --type ts --type js
rg "Bun\.(read|write)" --type ts --type js

# Missing parallel config
# Check test runner config files for parallel/concurrent settings
rg "\"parallel\":|\"concurrent\":|\"workers\":" jest.config.* vitest.config.* .bun

# Database operations
rg "\.query\(|\.execute\(|\.run\(" --type ts --type js
```

### Thresholds

| Pattern                                                 | Severity |
| ------------------------------------------------------- | -------- |
| `beforeAll`/`beforeEach` block > 20 lines               | Warning  |
| `beforeAll`/`beforeEach` block > 50 lines               | Critical |
| `fetch`/`axios`/`http` without corresponding mock setup | Critical |
| `fs.readFile`/`fs.writeFile` in unit tests              | Warning  |
| No parallel configuration in test runner config         | Warning  |
| Database queries in unit tests without mocking          | Critical |

### False positives

- Integration tests are expected to have real I/O — only flag file/network I/O in unit tests.
- `fs.readFile` for loading test fixtures from a `fixtures/` directory is standard practice.
- `beforeAll` with database migration in integration test suites is expected.
- Some test runners (Bun) run in parallel by default — check runner documentation before flagging missing config.
- Mocked `fetch` (via `jest.mock`, `vi.mock`, `msw`, or `nock`) should not be flagged as unmocked network calls.
