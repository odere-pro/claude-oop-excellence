# Testing Antipattern Detection Examples

## Table of contents

- [Example 1: Flaky test with hardcoded delays and shared state](#example-1-flaky-test-with-hardcoded-delays-and-shared-state)
- [Example 2: Implementation detail testing with internal spies](#example-2-implementation-detail-testing-with-internal-spies)
- [Example 3: Ice Cream Cone with slow E2E-heavy suite](#example-3-ice-cream-cone-with-slow-e2e-heavy-suite)

## Example 1: Flaky test with hardcoded delays and shared state

### Input test file (`tests/user-service.test.ts`)

```typescript
import { UserService } from '../src/user-service';

describe('UserService', () => {
  let service: UserService;
  let lastCreatedUser: any; // shared mutable state

  beforeAll(() => {
    service = new UserService();
  });

  it('should create a user', async () => {
    lastCreatedUser = await service.createUser({ name: 'Alice' });
    expect(lastCreatedUser.id).toBeDefined();
  });

  it('should find the created user', async () => {
    // depends on previous test's side effect
    await new Promise((resolve) => setTimeout(resolve, 2000));
    const found = await service.findUser(lastCreatedUser.id);
    expect(found.name).toBe('Alice');
  });

  it('should handle concurrent updates', async () => {
    const timestamp = Date.now();
    await service.updateUser(lastCreatedUser.id, { updatedAt: timestamp });
    const user = await service.findUser(lastCreatedUser.id);
    expect(user.updatedAt).toBe(timestamp);
  });
});
```

### Report output

```
# Testing Antipattern Report

**Test files scanned:** 1
**Test distribution:** 1 unit / 0 integration / 0 E2E
**Pyramid health:** missing-layer
**Findings:** 2 critical, 1 warnings, 0 info

## Critical
- [Flaky Tests] tests/user-service.test.ts:18 — setTimeout with 2000ms hardcoded delay creates timing dependency
- [Flaky Tests] tests/user-service.test.ts:24 — Date.now() used in equality assertion (toBe) — non-deterministic if clock skew occurs

## Warnings
- [Flaky Tests] tests/user-service.test.ts:5 — Shared `let lastCreatedUser` mutated across tests without beforeEach reset — test order dependency

## Test Health Score: 5/10
The test suite has multiple flakiness indicators. The shared mutable state (`lastCreatedUser`) creates implicit dependencies between tests — if the first test fails, subsequent tests will also fail. Replace the 2000ms setTimeout with proper async waiting or mocking. Use `beforeEach` to create fresh test data for each test case. Replace `Date.now()` with a fixed timestamp injected via dependency injection or clock mocking.
```

## Example 2: Implementation detail testing with internal spies

### Input test file (`tests/order-processor.test.ts`)

```typescript
import { OrderProcessor } from '../src/order-processor';

describe('OrderProcessor', () => {
  it('should validate before processing', () => {
    const processor = new OrderProcessor();
    const validateSpy = jest.spyOn(processor as any, '_validateOrder');
    const enrichSpy = jest.spyOn(processor as any, '_enrichOrderData');

    processor.processOrder({ id: '123', items: [{ sku: 'A1', qty: 1 }] });

    expect(validateSpy).toHaveBeenCalledBefore(enrichSpy);
    expect(validateSpy).toHaveBeenCalledWith({ id: '123', items: [{ sku: 'A1', qty: 1 }] });
    expect((processor as any)._lastValidationResult).toBe(true);
  });

  it('should call external pricing service', () => {
    const processor = new OrderProcessor();
    const fetchSpy = jest.spyOn(global, 'fetch');

    processor.processOrder({ id: '456', items: [{ sku: 'B2', qty: 3 }] });

    expect(fetchSpy).toHaveBeenCalledWith(
      'https://pricing.internal.api/v2/calculate',
      expect.objectContaining({ method: 'POST' }),
    );
  });
});
```

### Report output

```
# Testing Antipattern Report

**Test files scanned:** 1
**Test distribution:** 1 unit / 0 integration / 0 E2E
**Pyramid health:** missing-layer
**Findings:** 3 critical, 1 warnings, 0 info

## Critical
- [Testing Implementation Details] tests/order-processor.test.ts:4 — Spying on private method `_validateOrder` via `as any` cast — test will break on internal refactoring
- [Testing Implementation Details] tests/order-processor.test.ts:5 — Spying on private method `_enrichOrderData` via `as any` cast — couples test to implementation
- [Testing Implementation Details] tests/order-processor.test.ts:10 — Accessing private field `_lastValidationResult` via `as any` cast — asserts on internal state

## Warnings
- [Testing Implementation Details] tests/order-processor.test.ts:8 — `toHaveBeenCalledBefore` asserts on call order — fragile if internal execution order changes

## Test Health Score: 4/10
These tests are heavily coupled to the internal implementation of OrderProcessor. If the class is refactored (renaming private methods, changing execution order, restructuring internals), all tests will break even if the public behavior is unchanged. Rewrite tests to assert on observable outputs: verify that `processOrder` returns the correct result, throws on invalid input, and produces the expected side effects (database records, events) rather than checking which private methods were called in which order.
```

## Example 3: Ice Cream Cone with slow E2E-heavy suite

### Input: project-wide scan

```
tests/
  e2e/
    login.e2e.test.ts
    checkout.e2e.test.ts
    search.e2e.test.ts
    profile.e2e.test.ts
    cart.e2e.test.ts
    payment.e2e.test.ts
    admin-dashboard.e2e.test.ts
    inventory.e2e.test.ts
  integration/
    api-auth.integration.test.ts
    api-orders.integration.test.ts
  unit/
    utils.test.ts
    formatter.test.ts
```

With `tests/e2e/checkout.e2e.test.ts` containing:

```typescript
import { test, expect } from '@playwright/test';

test('full checkout flow', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.fill('#search', 'laptop');
  await page.click('button.search-submit');
  await new Promise((resolve) => setTimeout(resolve, 3000)); // wait for results
  await page.click('.product-card:first-child .add-to-cart');
  await page.click('#cart-icon');
  await page.fill('#coupon-code', 'SAVE10');
  await page.click('#apply-coupon');
  await new Promise((resolve) => setTimeout(resolve, 2000)); // wait for price update
  await page.click('#checkout-button');
  // ... 40 more lines of page interactions
});
```

### Report output

```
# Testing Antipattern Report

**Test files scanned:** 12
**Test distribution:** 2 unit / 2 integration / 8 E2E
**Pyramid health:** inverted
**Findings:** 3 critical, 2 warnings, 0 info

## Critical
- [Ice Cream Cone] project-wide — Inverted test pyramid: 8 E2E tests vs 2 unit tests (4:1 ratio). E2E tests are slow, expensive, and fragile. Extract business logic into unit-testable functions.
- [Flaky Tests] tests/e2e/checkout.e2e.test.ts:8 — setTimeout with 3000ms hardcoded delay instead of Playwright's built-in waiting mechanisms
- [Flaky Tests] tests/e2e/checkout.e2e.test.ts:12 — setTimeout with 2000ms hardcoded delay instead of using `page.waitForResponse` or `page.waitForSelector`

## Warnings
- [Slow Tests] tests/e2e/checkout.e2e.test.ts:5 — Single test case spans 40+ lines of sequential browser interactions — break into smaller focused tests
- [Slow Tests] project-wide — No parallel configuration detected for Playwright — add `workers` to playwright.config.ts

## Test Health Score: 3/10
The test suite has a severely inverted pyramid with 4x more E2E tests than unit tests. This causes slow CI pipelines, flaky failures, and high maintenance cost. Prioritize extracting business logic (pricing calculations, validation, cart operations) into pure functions with unit tests. Replace hardcoded `setTimeout` calls with Playwright's built-in waiting: `page.waitForSelector`, `page.waitForResponse`, or `expect(locator).toBeVisible()`. Configure parallel workers in Playwright to reduce overall E2E execution time.
```
