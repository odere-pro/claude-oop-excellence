# OpenSSF Best Practices — self-assessment

> Fill this in only when you decide to pursue the badge (worth it once the plugin has users). See the
> cookbook's `14-supply-chain-and-governance`.

The [OpenSSF Best Practices badge](https://www.bestpractices.dev/) is a self-assessment against an open
checklist. Register the repo to get a numeric project id, then add the (currently commented) badge to
[`../README.md`](../README.md) with that id. Keep the evidence here so the answers stay reviewable.

| Criterion             | Status | Evidence                                            |
| --------------------- | ------ | --------------------------------------------------- |
| Project homepage      | ⬜     | REPLACE ME                                          |
| OSS license           | ✅     | `LICENSE` (MIT)                                     |
| Documentation         | ⬜     | REPLACE ME                                          |
| Version control       | ✅     | public git; Conventional Commits                    |
| Release notes         | ✅     | `CHANGELOG.md`                                      |
| Bug-reporting process | ✅     | GitHub issues + `SUPPORT.md`                        |
| Vulnerability report  | ✅     | `SECURITY.md` — private GitHub Security Advisories  |
| Automated test suite  | ✅     | `tests/gates/` run by `.github/workflows/ci.yml`    |
| Static analysis       | ⬜     | enable `codeql.yml` once public                     |
| Secured delivery      | ✅     | actions pinned by commit SHA                        |
| Dependency monitoring | ✅     | `.github/dependabot.yml`                            |
