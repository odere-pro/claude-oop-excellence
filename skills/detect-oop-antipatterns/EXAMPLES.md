# OOP Antipattern Detector -- Examples

Before/after examples demonstrating antipattern detection and recommended refactoring.

## Table of contents

- [Example 1: Anemic Domain Model + Feature Envy](#example-1-anemic-domain-model--feature-envy)
- [Example 2: God Class refactored with extraction](#example-2-god-class-refactored-with-extraction)
- [Example 3: Refused Bequest + Yo-Yo Problem](#example-3-refused-bequest--yo-yo-problem)

---

## Example 1: Anemic Domain Model + Feature Envy

### Before (antipattern detected)

```typescript
// models/order.ts
class Order {
  id: string;
  items: OrderItem[];
  status: string;
  customerId: string;

  constructor(id: string, items: OrderItem[], customerId: string) {
    this.id = id;
    this.items = items;
    this.status = 'pending';
    this.customerId = customerId;
  }

  getItems() {
    return this.items;
  }
  getStatus() {
    return this.status;
  }
  setStatus(s: string) {
    this.status = s;
  }
  getCustomerId() {
    return this.customerId;
  }
}

// services/order-service.ts
class OrderService {
  calculateTotal(order: Order): number {
    // Feature Envy: 4+ accesses to order's data
    let total = 0;
    for (const item of order.getItems()) {
      total += item.getPrice() * item.getQuantity();
    }
    if (order.getStatus() === 'vip') {
      total *= 0.9;
    }
    return total;
  }

  canCancel(order: Order): boolean {
    return order.getStatus() === 'pending' && order.getItems().length > 0;
  }
}
```

**Report output:**

```
- [Anemic Domain Model] models/order.ts:2 `Order` — 4 fields, 0 business methods; logic in OrderService
- [Feature Envy] services/order-service.ts:4 `OrderService.calculateTotal` — 4 accesses to `order` (getItems, getStatus, getPrice, getQuantity)
```

### After (refactored)

```typescript
// models/order.ts
class Order {
  constructor(
    readonly id: string,
    private items: OrderItem[],
    private status: string,
    readonly customerId: string,
  ) {}

  calculateTotal(): number {
    const subtotal = this.items.reduce((sum, item) => sum + item.lineTotal(), 0);
    return this.status === 'vip' ? subtotal * 0.9 : subtotal;
  }

  canCancel(): boolean {
    return this.status === 'pending' && this.items.length > 0;
  }
}
```

**Why this fixes it:** Business logic moves into the class that owns the data. `OrderService` is no longer needed for these operations. `OrderItem.lineTotal()` encapsulates its own calculation.

---

## Example 2: God Class refactored with extraction

### Before (antipattern detected)

```python
# app/user_manager.py
class UserManager:
    """Handles users, auth, email, billing, reporting, and notifications."""

    def create_user(self, data): ...
    def update_user(self, user_id, data): ...
    def delete_user(self, user_id): ...
    def find_user(self, query): ...
    def authenticate(self, username, password): ...
    def refresh_token(self, token): ...
    def revoke_token(self, token): ...
    def send_welcome_email(self, user): ...
    def send_password_reset(self, user): ...
    def send_invoice(self, user): ...
    def charge_subscription(self, user): ...
    def cancel_subscription(self, user): ...
    def generate_usage_report(self, user): ...
    def generate_billing_report(self, user): ...
    def send_push_notification(self, user, message): ...
    def send_sms(self, user, message): ...
    # ... 20+ more methods spanning auth, email, billing, reports
```

**Report output:**

```
- [God Class] app/user_manager.py:2 `UserManager` — 35 methods, 800 lines, imports from 12 modules
```

### After (refactored)

```python
# app/users/repository.py
class UserRepository:
    def create(self, data): ...
    def update(self, user_id, data): ...
    def delete(self, user_id): ...
    def find(self, query): ...

# app/auth/service.py
class AuthService:
    def authenticate(self, username, password): ...
    def refresh_token(self, token): ...
    def revoke_token(self, token): ...

# app/notifications/service.py
class NotificationService:
    def send_email(self, user, template): ...
    def send_push(self, user, message): ...
    def send_sms(self, user, message): ...

# app/billing/service.py
class BillingService:
    def charge_subscription(self, user): ...
    def cancel_subscription(self, user): ...
    def generate_report(self, user): ...
```

**Why this fixes it:** Each class has a single responsibility. The original class is split along domain boundaries (users, auth, notifications, billing). Each resulting class is under 10 methods.

---

## Example 3: Refused Bequest + Yo-Yo Problem

### Before (antipattern detected)

```typescript
// Yo-Yo: 4 levels deep
class Shape {
  draw(): void {
    /* base */
  }
}
class Polygon extends Shape {
  override draw() {
    /* polygon */
  }
}
class RegularPolygon extends Polygon {
  override draw() {
    /* regular */
  }
}
class Square extends RegularPolygon {
  override draw() {
    /* square */
  }
}
class ColoredSquare extends Square {
  // Refused Bequest: overrides parent but throws
  override draw(): void {
    throw new Error('Not supported — use drawWithColor() instead');
  }

  drawWithColor(color: string): void {
    /* actual implementation */
  }
}
```

**Report output:**

```
- [Yo-Yo Problem] shapes.ts:5 `ColoredSquare` — inheritance depth 5 (Shape > Polygon > RegularPolygon > Square > ColoredSquare)
- [Refused Bequest] shapes.ts:7 `ColoredSquare.draw` — overrides parent method with throw
```

### After (refactored)

```typescript
interface Drawable {
  draw(options?: DrawOptions): void;
}

interface DrawOptions {
  color?: string;
}

class Square implements Drawable {
  constructor(private sideLength: number) {}

  draw(options?: DrawOptions): void {
    const color = options?.color ?? 'black';
    // draw square with color
  }
}
```

**Why this fixes it:** Composition via interface replaces the deep inheritance chain. `ColoredSquare` is no longer needed -- `Square` accepts draw options directly. The inheritance hierarchy is flattened from 5 levels to 1 (just implements an interface). No methods are refused because the contract is simple and the class fulfills it completely.
