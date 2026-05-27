# Reference: Architecture Antipattern Detection

Detailed detection strategies, thresholds, grep patterns, false positive guidance, and severity rules for each antipattern.

## Table of contents

- [Big Ball of Mud](#big-ball-of-mud)
- [Vendor Lock-In](#vendor-lock-in)
- [Reinventing the Wheel](#reinventing-the-wheel)
- [Architecture by Implication](#architecture-by-implication)
- [Stovepipe System](#stovepipe-system)
- [General guidelines](#general-guidelines)

## Big Ball of Mud

### Detection strategy

1. **Import graph breadth.** For each source file, extract all import/require statements and resolve the directory of each imported module. Count distinct directories.
   - Threshold: >5 distinct directories = flag
   - Threshold: >8 distinct directories = critical

2. **Layer violation analysis.** Define expected layers from directory names:
   - Presentation: `pages/`, `views/`, `components/`, `routes/`, `controllers/`
   - Business: `services/`, `domain/`, `core/`, `lib/`, `use-cases/`
   - Data: `models/`, `repositories/`, `dal/`, `db/`
   - Infrastructure: `infrastructure/`, `adapters/`, `providers/`, `config/`

   Flag imports that skip layers (e.g., a controller importing directly from a repository).

3. **Circular dependency check.** Look for files that import each other directly or through short cycles (A imports B, B imports A).

### Grep patterns

```
# ES module imports — extract directory
import .* from ['"]\.?\./

# CommonJS requires
require\(['"]\.?\./

# Python imports
from \w+ import
```

### False positive guidance

- Barrel files (`index.ts`) that re-export from many directories are not violations. Check the consuming file, not the barrel.
- Test files naturally import from many directories. Exclude `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`.
- Configuration files and scripts are exempt.

### Severity rules

| Condition                                         | Severity |
| ------------------------------------------------- | -------- |
| >50% of source files import from >5 directories   | Critical |
| 20-50% of source files import from >5 directories | Warning  |
| <20% of source files, or only in utility modules  | Info     |
| No layer structure exists at all (flat directory) | Critical |

---

## Vendor Lock-In

### Detection strategy

1. **Identify vendor-specific imports.** Scan for SDK imports in business logic directories.
2. **Check for abstraction layers.** If vendor imports exist only in `infrastructure/`, `adapters/`, `providers/`, or similarly named directories, the coupling is managed.
3. **Assess blast radius.** Count how many files directly import vendor SDKs. More files = higher severity.

### Grep patterns

```
# AWS
@aws-sdk/
aws-sdk
boto3
botocore

# GCP
@google-cloud/
google-cloud
google.cloud

# Azure
@azure/
azure-storage
azure-identity

# Firebase
firebase/
firebase-admin

# Specific services used as general imports
dynamodb|DynamoDB
s3\.putObject|s3\.getObject
SQS|SNS|Lambda
```

### False positive guidance

- Vendor imports in infrastructure/adapter directories are acceptable — that is the correct placement.
- CLI tools and deployment scripts are exempt.
- Test mocks of vendor services are exempt.
- A single vendor import in a clearly labeled adapter file is not lock-in.

### Severity rules

| Condition                                       | Severity   |
| ----------------------------------------------- | ---------- |
| Vendor SDK imported in >10 business logic files | Critical   |
| Vendor SDK in 3-10 business logic files         | Warning    |
| Vendor SDK in 1-2 files outside adapters        | Info       |
| All vendor usage behind abstraction layer       | No finding |

---

## Reinventing the Wheel

### Detection strategy

1. **Scan for custom implementations** of problems with well-established library solutions.
2. **Check package.json/requirements.txt** for whether the standard library is already a dependency (if yes, custom code is doubly suspicious).
3. **Assess complexity** of the custom implementation — trivial wrappers are acceptable.

### Grep patterns

```
# Custom HTTP clients
new XMLHttpRequest
http\.request\(
https\.request\(
# Complex fetch wrappers (retry, timeout, interceptors)
fetch\(.*retry|timeout.*fetch\(

# Custom date parsing
Date\.parse\(
\.split\(['"]-['"]\).*date
/\d{4}-\d{2}-\d{2}/

# Custom UUID generation
Math\.random\(\)\.toString\(36\)
Math\.random\(\)\.toString\(16\)
crypto\.randomBytes.*toString.*hex

# Custom JSON schema validation
function validate\(.*schema
validateSchema\(

# Custom crypto
crypto\.createHash\(
hashlib\.
MD5\(
SHA256\(
```

### False positive guidance

- Thin wrappers that add project-specific defaults around a library are acceptable.
- Code in a dedicated utility module with tests is less concerning than inline implementations.
- Performance-critical paths may justify custom implementations — flag as info, not warning.
- Standard library usage (e.g., Node `crypto` for hashing) in a utility module is acceptable.

### Severity rules

| Condition                                                  | Severity   |
| ---------------------------------------------------------- | ---------- |
| Custom HTTP client or crypto in production code            | Critical   |
| Custom date parsing or UUID generation spread across files | Warning    |
| Single-file utility with tests                             | Info       |
| Thin wrapper around established library                    | No finding |

---

## Architecture by Implication

### Detection strategy

1. **Check for architecture documentation.**
   - Look for: `adr/`, `adrs/`, `docs/adr/`, `docs/decisions/`, `ARCHITECTURE.md`, `docs/architecture*`, `.sdlc-autoflow/adrs/`
   - Missing all of the above = flag

2. **Check for conflicting patterns.** Scan for coexisting architectural styles:
   - MVC: `controllers/` + `models/` + `views/`
   - CQRS: `commands/` + `queries/` + `handlers/`
   - Clean Architecture: `use-cases/` + `entities/` + `interfaces/`
   - Repository pattern: files matching `*Repository*` or `*Repo*`
   - Active Record: model classes with `.save()`, `.find()`, `.create()` methods
   - REST + GraphQL: both `routes/` and `resolvers/` or `schema.graphql`

   Two or more conflicting patterns without documentation explaining the choice = flag.

3. **Naming inconsistency.** Check for mixed naming conventions that suggest no agreed-upon architecture:
   - `UserService` alongside `handle_user` alongside `userManager`
   - `getUser` vs `fetchUser` vs `loadUser` vs `retrieveUser` for similar operations

### Grep patterns

```
# ADR presence
adr/|adrs/|decisions/
ARCHITECTURE\.md

# Pattern detection
class.*Controller
class.*Handler
class.*Repository
class.*Service
\.save\(\)|\.find\(\)|\.create\(\)|\.update\(\)
resolvers|schema\.graphql|typeDefs
```

### False positive guidance

- Projects with a clear README section explaining architecture are not necessarily violations — check README for architecture mentions.
- Small projects (<20 files) may not need formal ADRs. Flag as info.
- Migration periods (moving from one pattern to another) should be documented but are not inherently antipatterns if intentional.

### Severity rules

| Condition                                           | Severity   |
| --------------------------------------------------- | ---------- |
| No architecture docs AND conflicting patterns       | Critical   |
| No architecture docs but consistent patterns        | Warning    |
| Architecture docs exist but are outdated (>1 year)  | Warning    |
| Architecture docs exist and patterns are consistent | No finding |

---

## Stovepipe System

### Detection strategy

1. **Duplicate type definitions.** Search for the same entity name defined as a type/interface/class in multiple directories.
2. **No shared contracts.** Check for the absence of a shared types directory (`shared/`, `contracts/`, `common/types/`, `@org/types`).
3. **Data model divergence.** Compare similarly named models across modules for field differences.

### Grep patterns

```
# Duplicate entity definitions
interface (User|Order|Product|Account|Payment|Invoice)[\s{]
type (User|Order|Product|Account|Payment|Invoice)\s*=
class (User|Order|Product|Account|Payment|Invoice)[\s{(]

# Shared contracts directory
shared/types|shared/contracts|common/types|@types/

# DTO proliferation
DTO|Dto|DataTransferObject
```

### False positive guidance

- A `User` type in a test fixture and a `User` type in production code is not duplication.
- Deliberately different representations (e.g., `UserEntity` for DB, `UserDTO` for API) are acceptable if there is a shared base or explicit mapping.
- Monorepo packages with their own type definitions may be intentional — check for a shared package.
- Frontend and backend having separate `User` types is common. Flag only if there is no shared contract or code generation.

### Severity rules

| Condition                                              | Severity   |
| ------------------------------------------------------ | ---------- |
| Same entity defined in >3 modules with no shared types | Critical   |
| Same entity in 2-3 modules without shared contracts    | Warning    |
| Minor duplication with clear mapping layer             | Info       |
| Shared contracts directory exists and is used          | No finding |

---

## General guidelines

### Sampling strategy for large codebases

When the codebase exceeds ~500 source files:

1. Analyze the top-level directory structure fully.
2. Sample 3-5 representative modules in depth.
3. Run grep patterns across the entire codebase for quantitative signals.
4. Note the sampling strategy in the report header.

### Combining findings

When multiple antipatterns appear together, note the combination explicitly:

- Big Ball of Mud + Architecture by Implication = likely no one owns the architecture
- Vendor Lock-In + Stovepipe = each team picked their own vendor independently
- Reinventing the Wheel + Stovepipe = teams do not share solutions

### Confidence levels

Mark each finding with implicit confidence:

- High confidence: pattern matches are unambiguous (e.g., AWS SDK in a service file)
- Medium confidence: pattern matches require context (e.g., custom date logic that might be intentional)
- Low confidence: structural observation that needs human judgment (e.g., directory naming)

For low-confidence findings, use info severity and explain the uncertainty.
