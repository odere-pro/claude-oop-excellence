# Antipattern Detection Examples

Before/after examples with expected report output.

## Table of contents

- [Example 1: God Object + Magic Numbers](#example-1-god-object--magic-numbers)
- [Example 2: Spaghetti Code + Lava Flow](#example-2-spaghetti-code--lava-flow)
- [Example 3: Circular Dependency + Poltergeist](#example-3-circular-dependency--poltergeist)

## Example 1: God Object + Magic Numbers

### Before

```typescript
// services/user-service.ts (620 lines, 22 exported functions)
export class UserService {
  public createUser(name: string, email: string, role: string) {
    /* ... */
  }
  public deleteUser(id: string) {
    /* ... */
  }
  public updateUser(id: string, data: any) {
    /* ... */
  }
  public getUserById(id: string) {
    /* ... */
  }
  public getUserByEmail(email: string) {
    /* ... */
  }
  public listUsers(page: number, limit: number) {
    /* ... */
  }
  public searchUsers(query: string) {
    /* ... */
  }
  public validateEmail(email: string) {
    /* ... */
  }
  public hashPassword(password: string) {
    /* ... */
  }
  public verifyPassword(password: string, hash: string) {
    /* ... */
  }
  public generateToken(userId: string) {
    /* ... */
  }
  public revokeToken(token: string) {
    /* ... */
  }
  public sendWelcomeEmail(userId: string) {
    /* ... */
  }
  public sendPasswordReset(email: string) {
    /* ... */
  }
  public logActivity(userId: string, action: string) {
    /* ... */
  }
  public exportUserData(userId: string) {
    /* ... */
  }
  // ... 6 more exported methods

  private calculateDiscount(total: number): number {
    if (total > 500) return total * 0.15;
    if (total > 200) return total * 0.1;
    if (total > 100) return total * 0.05;
    return 0;
  }

  private isEligible(age: number, score: number): boolean {
    return age >= 18 && score >= 750;
  }
}
```

### Expected report

````
# Code Antipattern Report

**Scanned:** 47 files in src/
**Findings:** 1 critical, 2 warnings, 0 info

## Critical
- [God Object] src/services/user-service.ts:1 — UserService has 620 lines and 22 exported methods. Combines user CRUD, authentication, email, and activity logging concerns.

## Warnings
- [Magic Numbers] src/services/user-service.ts:142 — Numeric literal 500 in discount conditional without named constant
- [Magic Numbers] src/services/user-service.ts:143 — Numeric literals 200, 0.10 in discount conditional without named constant

## Recommendations
1. **God Object (UserService):** Extract into cohesive modules:
   - `UserRepository` — CRUD operations (createUser, deleteUser, updateUser, getUserById, getUserByEmail, listUsers, searchUsers)
   - `AuthService` — authentication (hashPassword, verifyPassword, generateToken, revokeToken)
   - `NotificationService` — emails (sendWelcomeEmail, sendPasswordReset)
   - `ActivityLogger` — logging (logActivity)
   - `UserExporter` — data export (exportUserData)
2. **Magic Numbers:** Extract discount thresholds to named constants:
   ```typescript
   const DISCOUNT_TIERS = {
     HIGH: { threshold: 500, rate: 0.15 },
     MEDIUM: { threshold: 200, rate: 0.10 },
     LOW: { threshold: 100, rate: 0.05 },
   } as const;
````

````

### After (with --fix applied)

```typescript
// services/user-repository.ts
export class UserRepository {
  public createUser(name: string, email: string, role: string) { /* ... */ }
  public deleteUser(id: string) { /* ... */ }
  public updateUser(id: string, data: any) { /* ... */ }
  public getUserById(id: string) { /* ... */ }
  public getUserByEmail(email: string) { /* ... */ }
  public listUsers(page: number, limit: number) { /* ... */ }
  public searchUsers(query: string) { /* ... */ }
}

// services/auth-service.ts
export class AuthService {
  public validateEmail(email: string) { /* ... */ }
  public hashPassword(password: string) { /* ... */ }
  public verifyPassword(password: string, hash: string) { /* ... */ }
  public generateToken(userId: string) { /* ... */ }
  public revokeToken(token: string) { /* ... */ }
}

// services/discount.ts
const DISCOUNT_TIERS = {
  HIGH: { threshold: 500, rate: 0.15 },
  MEDIUM: { threshold: 200, rate: 0.10 },
  LOW: { threshold: 100, rate: 0.05 },
} as const;

export function calculateDiscount(total: number): number {
  for (const tier of Object.values(DISCOUNT_TIERS)) {
    if (total > tier.threshold) return total * tier.rate;
  }
  return 0;
}
````

---

## Example 2: Spaghetti Code + Lava Flow

### Before

```typescript
// handlers/process-order.ts
export function processOrder(order: Order, user: User, config: Config) {
  // TODO: remove this after migration (2024-03-15)
  // const oldFormat = convertLegacy(order);
  // if (oldFormat.version < 2) {
  //   return handleLegacyOrder(oldFormat);
  // }

  if (order.items.length > 0) {
    for (const item of order.items) {
      if (item.type === 'physical') {
        if (item.weight > 0) {
          if (config.shipping.enabled) {
            if (user.address) {
              if (user.address.country === 'US') {
                // HACK: hardcoded shipping zones
                const zone = getZone(user.address.zip);
                if (zone === 1) {
                  item.shippingCost = 5.99;
                } else if (zone === 2) {
                  item.shippingCost = 9.99;
                } else {
                  item.shippingCost = 14.99;
                }
              }
            }
          }
        }
      }
    }
  }
  // ... 90 more lines of nested logic
}
```

### Expected report

```
# Code Antipattern Report

**Scanned:** 47 files in src/
**Findings:** 1 critical, 3 warnings, 0 info

## Critical
- [Spaghetti Code] src/handlers/process-order.ts:8 — processOrder is 120 lines with nesting depth of 7. Multiple concerns mixed: validation, shipping calculation, zone lookup.

## Warnings
- [Lava Flow] src/handlers/process-order.ts:2 — TODO dated 2024-03-15 references migration removal, 2+ years old
- [Lava Flow] src/handlers/process-order.ts:3-5 — 3 lines of commented-out code (legacy order handling)
- [Magic Numbers] src/handlers/process-order.ts:18-22 — Hardcoded shipping costs 5.99, 9.99, 14.99 without named constants

## Recommendations
1. **Spaghetti Code:** Apply early-return guards and extract shipping calculation:
   - Guard: `if (order.items.length === 0) return;`
   - Extract: `calculateShippingCost(item, user, config): number`
   - Extract: `getShippingRate(zone: number): number`
2. **Lava Flow:** Remove the commented-out legacy code block (lines 2-5). The TODO is over 2 years old. If the migration is complete, delete it. If not, create a tracked issue.
3. **Magic Numbers:** Extract shipping rates to a configuration constant or lookup table.
```

### After (with --fix applied)

```typescript
// handlers/process-order.ts
const SHIPPING_RATES: Record<number, number> = {
  1: 5.99,
  2: 9.99,
};
const DEFAULT_SHIPPING_RATE = 14.99;

export function processOrder(order: Order, user: User, config: Config) {
  if (order.items.length === 0) return;

  for (const item of order.items) {
    if (item.type !== 'physical') continue;
    if (item.weight <= 0) continue;

    item.shippingCost = calculateShippingCost(item, user, config);
  }
}

function calculateShippingCost(item: OrderItem, user: User, config: Config): number {
  if (!config.shipping.enabled) return 0;
  if (!user.address || user.address.country !== 'US') return 0;

  const zone = getZone(user.address.zip);
  return SHIPPING_RATES[zone] ?? DEFAULT_SHIPPING_RATE;
}
```

---

## Example 3: Circular Dependency + Poltergeist

### Before

```typescript
// models/user.ts
import { Order } from './order';
export class User {
  orders: Order[] = [];
  getActiveOrders(): Order[] {
    return this.orders.filter((o) => o.isActive());
  }
}

// models/order.ts
import { User } from './user';
export class Order {
  owner: User;
  constructor(owner: User) {
    this.owner = owner;
  }
  isActive(): boolean {
    return this.status === 'active';
  }
  getOwnerName(): string {
    return this.owner.name;
  }
}

// services/order-proxy.ts
import { OrderService } from './order-service';
export class OrderProxy {
  constructor(private service: OrderService) {}
  createOrder(data: OrderData) {
    return this.service.createOrder(data);
  }
  getOrder(id: string) {
    return this.service.getOrder(id);
  }
}
```

### Expected report

```
# Code Antipattern Report

**Scanned:** 47 files in src/
**Findings:** 1 critical, 1 warning, 0 info

## Critical
- [Circular Dependency] src/models/user.ts <-> src/models/order.ts — User imports Order, Order imports User. Runtime initialization order may cause undefined references.

## Warnings
- [Poltergeist] src/services/order-proxy.ts:3 — OrderProxy has 2 methods that only delegate to OrderService with no added logic, validation, or error handling.

## Recommendations
1. **Circular Dependency:** Break the cycle by extracting the shared type:
   - Create `models/types.ts` with `OrderStatus` and `OrderSummary` interfaces
   - `User` references `OrderSummary` (no import of `Order`)
   - `Order` references `UserId` (no import of `User`)
2. **Poltergeist:** Remove `OrderProxy` and use `OrderService` directly. If the proxy exists for future caching or access control, document the intent or implement the additional behavior now.
```

### After (with --fix applied)

```typescript
// models/types.ts
export interface OrderSummary {
  id: string;
  status: string;
  isActive: boolean;
}

export type UserId = string;

// models/user.ts
import { OrderSummary } from './types';
export class User {
  orders: OrderSummary[] = [];
  getActiveOrders(): OrderSummary[] {
    return this.orders.filter((o) => o.isActive);
  }
}

// models/order.ts
import { UserId } from './types';
export class Order {
  ownerId: UserId;
  constructor(ownerId: UserId) {
    this.ownerId = ownerId;
  }
  isActive(): boolean {
    return this.status === 'active';
  }
}

// OrderProxy removed — consumers use OrderService directly
```
