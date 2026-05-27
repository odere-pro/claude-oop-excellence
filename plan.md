# Plan — is `claude-oop-excellence` universal to any OOP language?

> Working doc (author-facing). Tracks whether the plugin's detection and fix logic is genuinely
> language-agnostic, the assumptions that still leak a specific stack, and how to verify the claim.

## The claim

The manifest and README promise OOP-design enforcement "in any programming language — no framework,
stack, or paradigm lock-in." The detection knowledge (God Class, Anemic Domain Model, Feature Envy,
the GoF patterns, the antipattern catalogs) **is** language-neutral. The risk is in the *plumbing*:
file discovery, type checks, and test conventions that quietly assume one ecosystem.

## Target language matrix

Class/interface-based OOP languages the plugin should handle equally:

| Tier | Languages |
| ---- | --------- |
| Tier 1 (must) | Java, C#, TypeScript, Python, Kotlin |
| Tier 2 (should) | C++, Swift, Ruby, PHP, Scala |
| Tier 3 (struct/trait OOP) | Go, Rust |

## Universality audit — where a stack still leaks

Findings from the current component set, with status:

| # | Component | Leak | Status |
| - | --------- | ---- | ------ |
| 1 | `risk-scanner` orchestrator | File manifest was hardcoded to `.ts` globs + `.sdlc-autoflow` project paths | **Fixed** — now matches a broad extension set and is stack-detecting |
| 2 | Leaf scanners (`oop`, `code`, …) | Source glob `**/*.{ts,tsx,js,jsx,py,java,go,rs}` omits C#, C++, Kotlin, Swift, Ruby, PHP, Scala | **Open** — widen the glob to the matrix above |
| 3 | `audit` + `improve` `types` domain | Type check is `tsc --noEmit` only | **Open** — generalize to the project's type checker (mypy, `dotnet build`, `go vet`, `tsc`) or mark TS-only |
| 4 | Test scanner | Test-file conventions vary (`*_test.go`, `*Test.java`, `test_*.py`, `*.spec.ts`, `*Spec.kt`) | **Partial** — confirm the glob covers all matrix conventions |
| 5 | Dependency scanner | Manifest detection per ecosystem (`package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, `*.csproj`, `Cargo.toml`, `Gemfile`, `composer.json`) | **Verify** — enumerate manifests, not just npm |
| 6 | Database scanner | ORM list leaned JS/Python; now phrased ORM-agnostic incl. JPA/Hibernate, raw SQL | **Fixed** — verify with a JPA fixture |
| 7 | Thresholds (God Class > 500 lines / > 30 methods) | Line/method conventions differ (verbose Java vs terse Python) | **Accept with note** — thresholds are heuristics; scanners downgrade on uncertainty |

## What "universal" means here (acceptance criteria)

1. Running `/audit oop` on a minimal class-based project in **each Tier 1 language** surfaces a
   planted God Class and a planted Anemic Domain Model, with correct file/line evidence.
2. No component hard-codes a single language's file extension, type checker, or test convention as
   the *only* path; each either detects the stack or enumerates the matrix.
3. `pattern-detect` recognizes at least the creational/structural/behavioral GoF patterns in two
   different languages from the matrix.
4. The fix skills (`improve`, `pattern-implement`) run the *project's own* test/typecheck/lint
   command (detected, not assumed) before accepting a change.

## Verification plan

1. **Fixtures** — add tiny `examples/fixtures/<lang>/` projects (Java, C#, Python, Kotlin, TS) each
   with one deliberate God Class + one Anemic Domain Model. Keep them out of the shipped plugin
   (author-only, ignored or under `tests/`).
2. **Harness** — a gate or script runs `/audit oop component examples/fixtures/<lang>` per language
   and asserts both antipatterns are reported. (Manual until the scanners can run headless in CI.)
3. **Close the open leaks** (#2, #3, #4, #5) — widen globs, generalize the type check, enumerate
   manifests and test conventions.
4. **Re-audit** this table; flip every row to Fixed/Verified before claiming Tier 1 coverage.

## Next actions

- [ ] Widen leaf-scanner source globs to the Tier 1+2 matrix (#2).
- [ ] Generalize the `types` domain beyond `tsc` or relabel it `types (TypeScript)` (#3).
- [ ] Enumerate test-file and dependency-manifest conventions across the matrix (#4, #5).
- [ ] Add per-language fixtures and a verification script (verification plan 1–2).
