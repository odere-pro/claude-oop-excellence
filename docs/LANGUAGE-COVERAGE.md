# Language coverage

`claude-oop-excellence` is **language-agnostic**. Detection lives as universal design principles
plus language-neutral signs — not as a per-language matrix or a tiered list of "supported"
languages.

## Principles, not a matrix

Universality comes from three things, in this order:

1. **Universal design principles** — SOLID, encapsulation, cohesion/coupling, the Law of Demeter,
   DRY/KISS/YAGNI, composition-over-inheritance, tell-don't-ask.
2. **Language-neutral signs** — every entity in `skills/glossary/glossary.json` describes how to
   recognize it in plain natural language, never as a regex. Workers apply per-language judgment.
3. **Design patterns from the GoF catalog (and beyond)** — Strategy, Facade, Decorator, and the
   other 54 patterns shipped in the glossary; the orchestrator suggests fits regardless of stack.

## Stack detection at runtime

The orchestrator detects the stack from the **file manifest** of the scope it was given — there are
no extension globs hard-coded in the architecture and no per-language type-checker baked in. Each
worker applies its own language judgment to the injected entity record.

## Exercised targets vs. supported languages

**TypeScript / JavaScript** and **Python** are the languages this plugin is most heavily *exercised*
against — but they are **not** a hardcoded language tier. The architecture has no concept of
"supported languages": if the model can read the source, the plugin can audit it.

## Verification uses your project's own tooling

`/fix-risks` and `/implement-patterns` verify each change by running the project's **own detected**
test, typecheck, and lint commands — `npm test`, `pytest`, `make test`, `go test ./...`,
`cargo test`, whatever your repo already uses. There is no single-language tooling assumption and no
embedded test runner.

If your project has tests, the plugin runs them. If it doesn't, fixes are still applied but only
verified by the model's static reasoning — add tests for higher confidence.
