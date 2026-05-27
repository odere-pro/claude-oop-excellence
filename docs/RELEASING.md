# Releasing claude-oop-excellence

This is a Claude Code **plugin**, distributed through a marketplace — not npm. A "release" is a git tag
plus a GitHub Release. The version of record is `.claude-plugin/plugin.json` → `version` (the
marketplace entry omits `version` so there is one source of truth).

## Cut a release

1. **Bump** `version` in `.claude-plugin/plugin.json` ([SemVer](https://semver.org)).
2. **Add a `CHANGELOG.md` section** `## [X.Y.Z] - YYYY-MM-DD` describing the change.
3. **Verify** locally: `claude plugin validate . --strict` (and your gate suite, if you have one).
4. **Tag and push:**

   ```bash
   git commit -am "chore(release): vX.Y.Z"
   git tag vX.Y.Z          # MUST equal plugin.json version — the release workflow asserts this
   git push origin HEAD --tags
   ```

Pushing the `vX.Y.Z` tag triggers [`../.github/workflows/release.yml`](../.github/workflows/release.yml),
which verifies the tag matches `plugin.json`, runs your gates if present, and creates the GitHub Release
from the matching `CHANGELOG.md` section.

## Optional: fragment-based changelog

Once concurrent PRs start colliding on `CHANGELOG.md`, switch to a fragment-per-PR workflow (each PR
drops a `changelog/<NN>-<slug>.md`, aggregated at release time). It is documented, with the gates and
aggregator script, in the cookbook's `14-supply-chain-and-governance`. Until then, editing
`CHANGELOG.md` by hand is simpler.
