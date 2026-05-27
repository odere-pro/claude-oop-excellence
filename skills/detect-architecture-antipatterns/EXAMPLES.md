# Examples: Architecture Antipattern Detection

## Table of contents

- [Example 1: E-commerce monolith with multiple antipatterns](#example-1-e-commerce-monolith-with-multiple-antipatterns)
- [Example 2: Well-structured project with minor findings](#example-2-well-structured-project-with-minor-findings)
- [Example 3: Stovepipe microservices](#example-3-stovepipe-microservices)

## Example 1: E-commerce monolith with multiple antipatterns

**Invocation:** `/detect-architecture-antipatterns src/`

**Output:**

```
# Architecture Antipattern Report

**Scanned:** src/
**Module count:** 12
**Findings:** 2 critical, 3 warnings, 1 info

## Critical
- [Big Ball of Mud] src/services/orderService.ts — Imports from 9 different directories
  (controllers, models, utils, config, middleware, validators, external, helpers, db).
  No layer separation enforced.
- [Architecture by Implication] project root — No ADR directory found. Conflicting patterns
  detected: MVC controllers in src/controllers/ coexist with CQRS command handlers in
  src/commands/. No documentation explains the dual approach.

## Warnings
- [Vendor Lock-In] src/services/notificationService.ts — Direct import of @aws-sdk/client-ses
  in business logic. No abstraction layer. 4 other service files also import AWS SDKs directly.
- [Stovepipe System] src/billing/types.ts, src/orders/types.ts, src/shipping/types.ts —
  `interface Address` defined independently in 3 modules with different field sets
  (billing has `taxId`, orders has `deliveryNotes`, shipping has `coordinates`).
  No shared Address contract.
- [Reinventing the Wheel] src/utils/httpClient.ts — Custom HTTP client (247 lines) with
  retry logic, timeout handling, and request interceptors. Project already depends on axios
  in package.json.

## Info
- [Reinventing the Wheel] src/utils/dateFormatter.ts — Custom date formatting functions
  (42 lines). Project does not depend on a date library. Consider adopting date-fns or
  similar if date handling grows.

## Architecture Health Summary
This codebase shows signs of organic growth without architectural governance. The most
urgent issues are:

1. **Establish architecture documentation.** Create an ADR directory and document the
   relationship between the MVC and CQRS patterns. Decide whether to converge on one
   approach or explicitly partition responsibilities.

2. **Extract shared contracts.** Create a `src/shared/types/` directory for cross-module
   entities like Address. Define a canonical representation and map to module-specific
   DTOs where needed.

3. **Introduce vendor abstraction.** Create `src/infrastructure/email/` and wrap the
   SES dependency. Other services should depend on an interface, not the SDK.

4. **Replace custom HTTP client.** Migrate to the existing axios dependency with a
   configured instance for project defaults.
```

## Example 2: Well-structured project with minor findings

**Invocation:** `/detect-architecture-antipatterns`

**Output:**

```
# Architecture Antipattern Report

**Scanned:** . (project root)
**Module count:** 8
**Findings:** 0 critical, 1 warning, 1 info

## Critical
(none detected)

## Warnings
- [Vendor Lock-In] src/infrastructure/storage/s3Client.ts — AWS S3 SDK used behind
  abstraction layer (good), but src/scripts/migrate-data.ts imports S3 directly.
  Migration script bypasses the storage interface.

## Info
- [Stovepipe System] src/api/types/User.ts, src/worker/types/UserEvent.ts — Similar
  User-related types in two modules. Both reference a shared base from @company/types,
  so divergence is intentional. No action needed.

## Architecture Health Summary
This codebase is well-structured with clear module boundaries, documented architecture
decisions (14 ADRs), and vendor abstractions in place. The only actionable item is
updating the data migration script to use the storage interface instead of importing
S3 directly.
```

## Example 3: Stovepipe microservices

**Invocation:** `/detect-architecture-antipatterns services/`

**Output:**

```
# Architecture Antipattern Report

**Scanned:** services/
**Module count:** 5 (auth, billing, inventory, orders, notifications)
**Findings:** 3 critical, 1 warning, 0 info

## Critical
- [Stovepipe System] services/*/models/user.ts — User model defined independently in
  all 5 services. Field names differ: `userId` (auth), `user_id` (billing),
  `customerId` (orders), `recipientId` (notifications), `accountId` (inventory).
  No shared contract or schema registry.
- [Stovepipe System] services/*/utils/ — Each service has its own logging utility,
  error handler, and config loader. No shared packages. Total duplicated utility
  code: ~1,200 lines.
- [Architecture by Implication] services/ — No top-level architecture documentation.
  Services use different frameworks (Express, Fastify, Koa) and different ORMs
  (Prisma, TypeORM, raw SQL). No ADRs explain these choices.

## Warnings
- [Reinventing the Wheel] services/billing/utils/retry.ts,
  services/orders/utils/retry.ts — Two independent retry implementations with
  different backoff strategies. Neither uses an established library.

## Info
(none)

## Architecture Health Summary
These services evolved independently without shared governance. Priority actions:

1. **Create a shared contracts package** (`@org/contracts`) with canonical entity
   definitions and event schemas. Each service maps to/from its internal representation.

2. **Extract shared utilities** (`@org/common`) for logging, error handling, config,
   and retry logic. Standardize on one implementation.

3. **Document technology choices.** Create ADRs explaining the framework and ORM
   selections. If the divergence is unintentional, plan convergence. If intentional,
   document the rationale.

4. **Standardize entity naming.** Agree on `userId` as the canonical identifier and
   update services incrementally.
```
