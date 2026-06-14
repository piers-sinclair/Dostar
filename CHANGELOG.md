# Changelog

## [0.8.0](https://github.com/piers-sinclair/Dostar/compare/v0.7.0...v0.8.0) (2026-06-14)


### Features

* **frontend:** add welcome page and Dostar nav link to home ([#414](https://github.com/piers-sinclair/Dostar/issues/414)) ([c5c8945](https://github.com/piers-sinclair/Dostar/commit/c5c8945c769de98d0dfda8922b8b776e38764e6e))
* **frontend:** establish orval-first hooks pattern and document it ([#420](https://github.com/piers-sinclair/Dostar/issues/420)) ([ce15b01](https://github.com/piers-sinclair/Dostar/commit/ce15b015b25359be4bd41076976ced6496ec187a))
* **frontend:** migrate todos to dedicated route and wire nav link in __root.tsx ([#412](https://github.com/piers-sinclair/Dostar/issues/412)) ([19dd92b](https://github.com/piers-sinclair/Dostar/commit/19dd92bc91ee448c108bbb03bb37b31c019dfe07))
* **frontend:** set dark mode as the default theme ([#417](https://github.com/piers-sinclair/Dostar/issues/417)) ([0b5e435](https://github.com/piers-sinclair/Dostar/commit/0b5e435f0c31f7666aea93f72b5d32af10360021))


### Bug Fixes

* **frontend:** remove stale --type list from welcome page add-feature example ([#419](https://github.com/piers-sinclair/Dostar/issues/419)) ([a4beda7](https://github.com/piers-sinclair/Dostar/commit/a4beda768fb1605e841bf76c892f49fd1ea778c7))
* **frontend:** show both remove-feature and remove-module commands on home page ([#416](https://github.com/piers-sinclair/Dostar/issues/416)) ([e739a26](https://github.com/piers-sinclair/Dostar/commit/e739a26efb96d8908e19464c4b3578f33d7352ef))


### Documentation

* add architecture.md with topology, CI/CD and spin-up diagrams ([#418](https://github.com/piers-sinclair/Dostar/issues/418)) ([a62d3dc](https://github.com/piers-sinclair/Dostar/commit/a62d3dcdfb2c3c2da159d6c196606b4fd8b07c1e))
* **claude:** add TDD guidance to CLAUDE.md and relevant skills ([#410](https://github.com/piers-sinclair/Dostar/issues/410)) ([25c0a81](https://github.com/piers-sinclair/Dostar/commit/25c0a81593935e543346d1686af144451033e29e)), closes [#409](https://github.com/piers-sinclair/Dostar/issues/409)

## [0.7.0](https://github.com/piers-sinclair/Dostar/compare/v0.6.0...v0.7.0) (2026-06-13)


### Features

* **backend:** add validation failure and correlation ID integration tests (Closes [#386](https://github.com/piers-sinclair/Dostar/issues/386)) ([#405](https://github.com/piers-sinclair/Dostar/issues/405)) ([125f1b8](https://github.com/piers-sinclair/Dostar/commit/125f1b8f5229c8d9e125f78c6cd901c3a2a356b9))
* **frontend:** add dostar sentinel comments around TodoList in routes/index.tsx ([#407](https://github.com/piers-sinclair/Dostar/issues/407)) ([99c51c9](https://github.com/piers-sinclair/Dostar/commit/99c51c9e6ce7e02dd16f166109eef78bed72b19e))


### Bug Fixes

* **security:** upgrade esbuild to 0.28.1 to resolve Dependabot alerts [#1](https://github.com/piers-sinclair/Dostar/issues/1) and [#2](https://github.com/piers-sinclair/Dostar/issues/2) ([#404](https://github.com/piers-sinclair/Dostar/issues/404)) ([47f7c26](https://github.com/piers-sinclair/Dostar/commit/47f7c26e232b5935f94ec6a65569757cc8f16111))


### Documentation

* add as-is disclaimer to README ([#406](https://github.com/piers-sinclair/Dostar/issues/406)) ([eaf6d78](https://github.com/piers-sinclair/Dostar/commit/eaf6d784f99e08773b203d97abfecb36f9853cb9))
* **claude:** document dostar sentinel comments in routes/index.tsx ([#408](https://github.com/piers-sinclair/Dostar/issues/408)) ([a1fa4a0](https://github.com/piers-sinclair/Dostar/commit/a1fa4a0def66b7dbce18b30421da01848e0005a6))
* **security:** soften liability language in SECURITY.md ([#402](https://github.com/piers-sinclair/Dostar/issues/402)) ([4204a8c](https://github.com/piers-sinclair/Dostar/commit/4204a8ce3e1e9821a532427da7cefaf36ef72ce8))

## [0.6.0](https://github.com/piers-sinclair/Dostar/compare/v0.5.0...v0.6.0) (2026-06-13)


### Features

* **agents:** add /scaffold-page skill and docs/routing.md (Closes [#383](https://github.com/piers-sinclair/Dostar/issues/383)) ([#401](https://github.com/piers-sinclair/Dostar/issues/401)) ([5b09415](https://github.com/piers-sinclair/Dostar/commit/5b094153f2cf25708028f77dfca0824f720a3d8b))
* **agents:** update scaffold skills for NotFoundException, LoggerMessage, and toast patterns (Closes [#388](https://github.com/piers-sinclair/Dostar/issues/388)) ([#400](https://github.com/piers-sinclair/Dostar/issues/400)) ([54c3aeb](https://github.com/piers-sinclair/Dostar/commit/54c3aebe4d6ba68af9c8797455c88b7ff9686d00))
* **backend:** add GlobalExceptionHandler and domain exception types ([#391](https://github.com/piers-sinclair/Dostar/issues/391)) ([2d5ebad](https://github.com/piers-sinclair/Dostar/commit/2d5ebad9b497cb508fa47001ce4312335954ede8))
* **backend:** add ILogger injection pattern to Todos module ([#393](https://github.com/piers-sinclair/Dostar/issues/393)) ([19b5053](https://github.com/piers-sinclair/Dostar/commit/19b5053cdc6d53ce459e7a7016dcc74cac7a1ca7))
* **frontend:** add global API error interceptor in apiClient ([#397](https://github.com/piers-sinclair/Dostar/issues/397)) ([af4053a](https://github.com/piers-sinclair/Dostar/commit/af4053a35018f18865fcf4f27a8feca38ac11a27))
* **frontend:** add global ErrorBoundary with fallback UI ([#395](https://github.com/piers-sinclair/Dostar/issues/395)) ([508120d](https://github.com/piers-sinclair/Dostar/commit/508120d29a03dfc3a228fa762287953e7a7a37ba))
* **frontend:** add global toast notification system for mutation errors (Closes [#381](https://github.com/piers-sinclair/Dostar/issues/381)) ([#396](https://github.com/piers-sinclair/Dostar/issues/396)) ([0abe693](https://github.com/piers-sinclair/Dostar/commit/0abe693eff4d1e5ac7400b195cf7d376617cf461))
* **frontend:** add success toast on CreateTodoForm submit ([#399](https://github.com/piers-sinclair/Dostar/issues/399)) ([7cdf08a](https://github.com/piers-sinclair/Dostar/commit/7cdf08a62cb040778591c8131cc99139e6a58a02)), closes [#387](https://github.com/piers-sinclair/Dostar/issues/387)
* **frontend:** add TanStack Router with two-level shell layout ([#392](https://github.com/piers-sinclair/Dostar/issues/392)) ([08d6795](https://github.com/piers-sinclair/Dostar/commit/08d679519f69acd19c7f383a298e2145c7920f6a))

## [0.5.0](https://github.com/piers-sinclair/Dostar/compare/v0.4.0...v0.5.0) (2026-06-13)


### Features

* **agents:** add /scaffold-feature skill and fix /scaffold-module test paths ([#372](https://github.com/piers-sinclair/Dostar/issues/372)) ([a4f01ec](https://github.com/piers-sinclair/Dostar/commit/a4f01ecefba8ba25ed635d68c132e3e4d2675d72)), closes [#371](https://github.com/piers-sinclair/Dostar/issues/371)
* **devcontainer:** add health check panel and improve error visibility ([#347](https://github.com/piers-sinclair/Dostar/issues/347)) ([9d8fa0f](https://github.com/piers-sinclair/Dostar/commit/9d8fa0ff3817bae1081114ea2daac9bef2762787)), closes [#339](https://github.com/piers-sinclair/Dostar/issues/339)
* **devcontainer:** show setup progress status on attach ([#348](https://github.com/piers-sinclair/Dostar/issues/348)) ([fae8937](https://github.com/piers-sinclair/Dostar/commit/fae89375d0c05bee3528942ce5cdd3d453f1ca23))
* issue 339 devcontainer health check ([#349](https://github.com/piers-sinclair/Dostar/issues/349)) ([28f0940](https://github.com/piers-sinclair/Dostar/commit/28f0940869d3d0a9962bc68a3598754745c64b74))
* restructure frontend to use feature-based folder organisation ([#345](https://github.com/piers-sinclair/Dostar/issues/345)) ([e2b5f42](https://github.com/piers-sinclair/Dostar/commit/e2b5f42e390ae3cf59514c35b18a9fa976efcd56))


### Bug Fixes

* add curl timeouts to smoke tests to prevent indefinite hangs ([#350](https://github.com/piers-sinclair/Dostar/issues/350)) ([9a81ecc](https://github.com/piers-sinclair/Dostar/commit/9a81ecc76891157b83fdeb1d64f7ca32e2d12884))
* **cd:** remove invalid skip_api_build input from SWA deploy action ([#360](https://github.com/piers-sinclair/Dostar/issues/360)) ([72438f0](https://github.com/piers-sinclair/Dostar/commit/72438f02347a672f24f4af0a67045120b003a437))
* **devcontainer:** add sudo to lefthook symlink so it can write to /usr/local/bin ([#342](https://github.com/piers-sinclair/Dostar/issues/342)) ([f550146](https://github.com/piers-sinclair/Dostar/commit/f550146b29c658b41e7ffc978b4f1f93b466f4f6))
* **devcontainer:** derive Docker Compose network name dynamically ([#339](https://github.com/piers-sinclair/Dostar/issues/339)) ([a19b9da](https://github.com/piers-sinclair/Dostar/commit/a19b9dab715623eeb064b52c76ea1fdbe922eaad)), closes [#338](https://github.com/piers-sinclair/Dostar/issues/338)
* **devcontainer:** explicitly run lefthook install after symlink setup ([#366](https://github.com/piers-sinclair/Dostar/issues/366)) ([cd9dad2](https://github.com/piers-sinclair/Dostar/commit/cd9dad2302d8b57959815e5aa82af52be7030c18))
* **devcontainer:** fix health command and protect dostar tool references from substitution ([#363](https://github.com/piers-sinclair/Dostar/issues/363)) ([a68cff8](https://github.com/piers-sinclair/Dostar/commit/a68cff861dd64c5075f74aadf10a4652b010e870))
* **devcontainer:** improve postgres network setup reliability and health diagnostics ([#364](https://github.com/piers-sinclair/Dostar/issues/364)) ([5273bd7](https://github.com/piers-sinclair/Dostar/commit/5273bd7c4f0af005c27c2833f64cdc61c7fb10f0))
* **devcontainer:** install Dostar CLI in postCreate.sh ([#340](https://github.com/piers-sinclair/Dostar/issues/340)) ([9b1f9c2](https://github.com/piers-sinclair/Dostar/commit/9b1f9c245545db4514605b6a021b5d39f7e1e88c)), closes [#336](https://github.com/piers-sinclair/Dostar/issues/336)
* **devcontainer:** make pnpm install fault-tolerant when git repo is missing ([#341](https://github.com/piers-sinclair/Dostar/issues/341)) ([a512dc5](https://github.com/piers-sinclair/Dostar/commit/a512dc5b6a867be4947e5d4eb82915d396b88375)), closes [#337](https://github.com/piers-sinclair/Dostar/issues/337)
* **devcontainer:** symlink lefthook to native binary instead of pnpm shim ([#346](https://github.com/piers-sinclair/Dostar/issues/346)) ([a9f25bc](https://github.com/piers-sinclair/Dostar/commit/a9f25bcc71042609d254441554238a7f2c7f50e6))
* handle curl non-zero exit in smoke test loop ([#352](https://github.com/piers-sinclair/Dostar/issues/352)) ([1283bf2](https://github.com/piers-sinclair/Dostar/commit/1283bf25f6cb8d25c5aef106e6d878d0ca9b1e7e))
* **infra:** add dependsOn rg to all resource-group-scoped modules ([#368](https://github.com/piers-sinclair/Dostar/issues/368)) ([231dd38](https://github.com/piers-sinclair/Dostar/commit/231dd38460b243fab4fdbc15b5c10f157e365cd8)), closes [#361](https://github.com/piers-sinclair/Dostar/issues/361)
* **infra:** remove smoke test from infra-deploy ([#356](https://github.com/piers-sinclair/Dostar/issues/356)) ([005803f](https://github.com/piers-sinclair/Dostar/commit/005803fdb649cb82112ccab6aaa00cee9ec51738))
* **infra:** replace Container App inline secret with Key Vault URI reference ([#359](https://github.com/piers-sinclair/Dostar/issues/359)) ([a0408f1](https://github.com/piers-sinclair/Dostar/commit/a0408f10b0ae0d6b5cf49b4fe13f98e357cc5070)), closes [#355](https://github.com/piers-sinclair/Dostar/issues/355)
* **infra:** revert KV secret reference, document write-only field trade-offs ([#362](https://github.com/piers-sinclair/Dostar/issues/362)) ([e3ff031](https://github.com/piers-sinclair/Dostar/commit/e3ff03176ffff8ed15c4bea7486acd8f07d2bf72)), closes [#355](https://github.com/piers-sinclair/Dostar/issues/355)
* **infra:** show ARM deployment progress in CI logs ([#358](https://github.com/piers-sinclair/Dostar/issues/358)) ([e4b8e01](https://github.com/piers-sinclair/Dostar/commit/e4b8e013f34f41d4b31f8207244269980c4de439))
* **infra:** skip smoke test in infra-deploy when called from infra-spinup + fix CAE listKeys idempotency ([#354](https://github.com/piers-sinclair/Dostar/issues/354)) ([a8894de](https://github.com/piers-sinclair/Dostar/commit/a8894de051c3ad5e2deffa74c59d8ea13fcf781f))
* **infra:** use rgName var in module scopes instead of rg.outputs.name ([#367](https://github.com/piers-sinclair/Dostar/issues/367)) ([0edbe9c](https://github.com/piers-sinclair/Dostar/commit/0edbe9cb14a91bcdcb734b802a4d71b9d9bd62bf))
* Modify CLI installation instructions in README ([#332](https://github.com/piers-sinclair/Dostar/issues/332)) ([76a11f8](https://github.com/piers-sinclair/Dostar/commit/76a11f81525e45870a40c6d624b078faf1f49d2d))
* remove fixed host port binding for PostgreSQL ([#370](https://github.com/piers-sinclair/Dostar/issues/370)) ([32a856e](https://github.com/piers-sinclair/Dostar/commit/32a856e7cb0d6b3737cf098d143a5b661fab21d6))
* remove spurious provider registration step that stalled infra deploys ([#353](https://github.com/piers-sinclair/Dostar/issues/353)) ([7898d9a](https://github.com/piers-sinclair/Dostar/commit/7898d9a84a149858877c300bd70de9cc16746f90))
* **vscode:** default Run and Debug picker to API + Frontend compound ([#375](https://github.com/piers-sinclair/Dostar/issues/375)) ([551b0f3](https://github.com/piers-sinclair/Dostar/commit/551b0f3938dadef8ec5b00edffe38f1d990eec9a))


### Documentation

* clarify three core goals in README and CLAUDE.md ([#334](https://github.com/piers-sinclair/Dostar/issues/334)) ([d91cb5b](https://github.com/piers-sinclair/Dostar/commit/d91cb5bc45d25d21831aa180581fdbb2cc2e7e55))
* **readme:** improve deploy UX — split exports, spin up infra, teardown, dev/prod story ([#376](https://github.com/piers-sinclair/Dostar/issues/376)) ([e724bd2](https://github.com/piers-sinclair/Dostar/commit/e724bd2ea5e67e746cc214173db574e61ed9943d))
* replace Todos smoke-test endpoint and note CLI handles workload rename ([#377](https://github.com/piers-sinclair/Dostar/issues/377)) ([d964769](https://github.com/piers-sinclair/Dostar/commit/d9647695e3e2c60d1ada3255302c0b7c660f2ab9))
* replace Todos-specific commit example with generic domain example ([#378](https://github.com/piers-sinclair/Dostar/issues/378)) ([39901e4](https://github.com/piers-sinclair/Dostar/commit/39901e40a690c1dca0e0f496f4f9f23a99b6e433))
* **skills:** add YAML frontmatter to all Claude Code skills ([#379](https://github.com/piers-sinclair/Dostar/issues/379)) ([ad94fa0](https://github.com/piers-sinclair/Dostar/commit/ad94fa0fcc60fa78863dcca1b69acd8dfc24874e))

## [0.4.0](https://github.com/piers-sinclair/Dostar/compare/v0.3.0...v0.4.0) (2026-06-12)


### Features

* add dev-workflow script to regenerate OpenAPI spec and orval client in one step ([#320](https://github.com/piers-sinclair/Dostar/issues/320)) ([c623aa5](https://github.com/piers-sinclair/Dostar/commit/c623aa57e1311a7e74e9ef46974764b5e82b51c1))
* **ci:** add lefthook pre-commit hooks for format and lint checks ([#324](https://github.com/piers-sinclair/Dostar/issues/324)) ([a0b716f](https://github.com/piers-sinclair/Dostar/commit/a0b716f4413fe52ae980f1bcddf87aa3d066bd1c))
* **ci:** add post-deploy smoke tests to all CD pipelines ([#315](https://github.com/piers-sinclair/Dostar/issues/315)) ([288fd79](https://github.com/piers-sinclair/Dostar/commit/288fd797ebc4ec967dfcc312f4aede4b4dca838f)), closes [#312](https://github.com/piers-sinclair/Dostar/issues/312)
* **infra:** observability audit — expand alerting and add health probes ([#323](https://github.com/piers-sinclair/Dostar/issues/323)) ([c3dbe45](https://github.com/piers-sinclair/Dostar/commit/c3dbe450f71c587a4abf0c5fc66eeefe40c27064)), closes [#321](https://github.com/piers-sinclair/Dostar/issues/321)
* **tests:** establish test pyramid ([#330](https://github.com/piers-sinclair/Dostar/issues/330)) ([fe45d6b](https://github.com/piers-sinclair/Dostar/commit/fe45d6b55c25c21ed8737e86a8ba5f99bfbe5f9a))
* wire orval to committed OpenAPI spec for type safety ([#317](https://github.com/piers-sinclair/Dostar/issues/317)) ([5db8d79](https://github.com/piers-sinclair/Dostar/commit/5db8d797edee1b23c3a14cc232e6b2f381eebe9c))


### Bug Fixes

* Add minimum length constraint to alertEmailAddress param ([#289](https://github.com/piers-sinclair/Dostar/issues/289)) ([cefd19e](https://github.com/piers-sinclair/Dostar/commit/cefd19e74f7daf120d648338d398e7b28fa82e19))
* **ci:** allow esbuild build scripts in pnpm-workspace.yaml ([#326](https://github.com/piers-sinclair/Dostar/issues/326)) ([e6ae0a9](https://github.com/piers-sinclair/Dostar/commit/e6ae0a9b7d57e1272b1fd8c851cb159f4332edb7))
* **ci:** make path-filtered CI checks always report to satisfy required checks ([#322](https://github.com/piers-sinclair/Dostar/issues/322)) ([efba01c](https://github.com/piers-sinclair/Dostar/commit/efba01cda56a110585d9e7d487b57f19c4482788))
* **ci:** trigger frontend checks when OpenAPI spec changes ([#325](https://github.com/piers-sinclair/Dostar/issues/325)) ([94040b8](https://github.com/piers-sinclair/Dostar/commit/94040b8d7e04ad4d89cd3f2c829ba73396dce2f8))
* **devcontainer:** make non-critical postCreate steps fault-tolerant ([#331](https://github.com/piers-sinclair/Dostar/issues/331)) ([583a808](https://github.com/piers-sinclair/Dostar/commit/583a80846e094b95b09b61ec1b745f8903eddca5))
* **frontend:** revert eslint-react and @types/node to pass supply-chain age policy ([#302](https://github.com/piers-sinclair/Dostar/issues/302)) ([e210214](https://github.com/piers-sinclair/Dostar/commit/e21021452a3f9fdad48470a68d0fb8bb14da4589))
* **infra:** fix availability web test null reference error ([#295](https://github.com/piers-sinclair/Dostar/issues/295)) ([a0b401a](https://github.com/piers-sinclair/Dostar/commit/a0b401ac35c721f93a43eea2732ae6d8db3e7809))
* **infra:** register Microsoft.AlertsManagement provider before deployment ([#308](https://github.com/piers-sinclair/Dostar/issues/308)) ([23f8760](https://github.com/piers-sinclair/Dostar/commit/23f87603b521aa1d71ed4c1eb320ff0d377ddac6))
* **infra:** remove availability test — unreliable across Azure regions ([#316](https://github.com/piers-sinclair/Dostar/issues/316)) ([faa3636](https://github.com/piers-sinclair/Dostar/commit/faa3636bd67f771e26c41265b375e8d38c08e1a2))
* **infra:** scope scheduled query alert rules to Log Analytics workspace ([#292](https://github.com/piers-sinclair/Dostar/issues/292)) ([486aa30](https://github.com/piers-sinclair/Dostar/commit/486aa30e199908f2c6a6673ab89b2e04aedf9da0))
* **infra:** use 2018-05-01-preview API version for webtests resource ([#314](https://github.com/piers-sinclair/Dostar/issues/314)) ([4b00de2](https://github.com/piers-sinclair/Dostar/commit/4b00de25170da83a086006241ad2ec990b3ba6ec))


### Documentation

* add GitHub repo setup + deploy steps to README quick start ([#296](https://github.com/piers-sinclair/Dostar/issues/296)) ([f4df3d3](https://github.com/piers-sinclair/Dostar/commit/f4df3d3578b48107bc4b9f23a9e67ff2cd38ba00)), closes [#293](https://github.com/piers-sinclair/Dostar/issues/293)
* fix F5/run:dev experience and add migration pre-launch step ([#310](https://github.com/piers-sinclair/Dostar/issues/310)) ([073d9e7](https://github.com/piers-sinclair/Dostar/commit/073d9e76d79cfa7848144a738d5dddd55e391009))
* review and streamline all markdown for a grad engineer audience ([#328](https://github.com/piers-sinclair/Dostar/issues/328)) ([dcdfe21](https://github.com/piers-sinclair/Dostar/commit/dcdfe21cd0db5af17270f7d42b9611078b4269ac))

## [0.3.0](https://github.com/piers-sinclair/Dostar/compare/v0.2.1...v0.3.0) (2026-06-11)


### Features

* **observability:** implement OpenTelemetry stack for production incident response ([#270](https://github.com/piers-sinclair/Dostar/issues/270)) ([1595214](https://github.com/piers-sinclair/Dostar/commit/1595214c1d149593290558c9ad308ecf313d1090))


### Bug Fixes

* **infra:** wire Container Apps Environment to Log Analytics ([#288](https://github.com/piers-sinclair/Dostar/issues/288)) ([754ea0d](https://github.com/piers-sinclair/Dostar/commit/754ea0d9c840b0d42e891773127ef6ece9acfc88))

## [0.2.1](https://github.com/piers-sinclair/Dostar/compare/v0.2.0...v0.2.1) (2026-06-11)


### Bug Fixes

* **ci:** chain cd-release from release-please instead of relying on tag push event ([#283](https://github.com/piers-sinclair/Dostar/issues/283)) ([8038322](https://github.com/piers-sinclair/Dostar/commit/8038322b37dbd56d6e51588bd2c37516cfc2d3ba))
* **ci:** grant id-token: write to release-please workflow for workflow_call ([#284](https://github.com/piers-sinclair/Dostar/issues/284)) ([69a4c82](https://github.com/piers-sinclair/Dostar/commit/69a4c82a400bbb8b1ef22d71cef8fdc1b9505f82))

## [0.2.0](https://github.com/piers-sinclair/Dostar/compare/v0.1.0...v0.2.0) (2026-06-11)


### Features

* add /add-package Claude skill with licence validation ([9a02376](https://github.com/piers-sinclair/Dostar/commit/9a023764d7b4b5f6296f315b76b02f94113b83e5))
* add /scaffold-module and /add-migration Claude skills ([a90b9a2](https://github.com/piers-sinclair/Dostar/commit/a90b9a202deaa42d8bae3f21e74cfcef47ebabd5))
* add /scaffold-module and /add-migration Claude skills ([12ec403](https://github.com/piers-sinclair/Dostar/commit/12ec4037176dc929312c6aa26444f1475de4143b)), closes [#36](https://github.com/piers-sinclair/Dostar/issues/36)
* add Application Insights and Log Analytics Workspace ([#31](https://github.com/piers-sinclair/Dostar/issues/31)) ([#151](https://github.com/piers-sinclair/Dostar/issues/151)) ([518464e](https://github.com/piers-sinclair/Dostar/commit/518464ecc72e281d59cc3f58a15e299e25bb209c))
* add azd-required outputs to main.bicep ([#174](https://github.com/piers-sinclair/Dostar/issues/174)) ([dd4335b](https://github.com/piers-sinclair/Dostar/commit/dd4335b06dba5dff71b02330c90a17a1f3daf77f)), closes [#169](https://github.com/piers-sinclair/Dostar/issues/169)
* add Azure Developer CLI (azd) to devcontainer ([#173](https://github.com/piers-sinclair/Dostar/issues/173)) ([f58d37a](https://github.com/piers-sinclair/Dostar/commit/f58d37a924f806ad7ff0cddccbf5207deb58955a)), closes [#168](https://github.com/piers-sinclair/Dostar/issues/168)
* add azure.yaml and predeploy hook for azd support ([#175](https://github.com/piers-sinclair/Dostar/issues/175)) ([13c15a4](https://github.com/piers-sinclair/Dostar/commit/13c15a46a68e5edf3372057dec0a3485153c7325)), closes [#170](https://github.com/piers-sinclair/Dostar/issues/170)
* add Bicep module for Azure Static Web Apps ([#146](https://github.com/piers-sinclair/Dostar/issues/146)) ([feef944](https://github.com/piers-sinclair/Dostar/commit/feef9449f1d45edf3c4839fd9c17b38de2b33ed2))
* add Bicep module for Key Vault ([#147](https://github.com/piers-sinclair/Dostar/issues/147)) ([be392ef](https://github.com/piers-sinclair/Dostar/commit/be392ef20196cb31b32499d76efbe142f0d8c460)), closes [#30](https://github.com/piers-sinclair/Dostar/issues/30)
* add Bicep module for PostgreSQL Flexible Server ([#149](https://github.com/piers-sinclair/Dostar/issues/149)) ([9d419f8](https://github.com/piers-sinclair/Dostar/commit/9d419f81f955ae214e0296ec0fbf28b8230bf431)), closes [#29](https://github.com/piers-sinclair/Dostar/issues/29)
* add Bicep module for VNet and subnets ([#145](https://github.com/piers-sinclair/Dostar/issues/145)) ([6c66cf8](https://github.com/piers-sinclair/Dostar/commit/6c66cf8cab746a4b58132a687d13cb933d37eafa)), closes [#32](https://github.com/piers-sinclair/Dostar/issues/32)
* add CI workflow for code-style enforcement ([2c04974](https://github.com/piers-sinclair/Dostar/commit/2c04974170617855977517fc309253f929a662d4))
* add CI workflow for code-style enforcement ([f5a1658](https://github.com/piers-sinclair/Dostar/commit/f5a1658b1a4714f2494ca963a70e9d8c12c08150))
* add Dependabot config with grouped weekly updates ([3a115b8](https://github.com/piers-sinclair/Dostar/commit/3a115b88f3f88a542c4da27a4343106f5ce81605))
* add Dependabot config with grouped weekly updates ([d6e9069](https://github.com/piers-sinclair/Dostar/commit/d6e90692c6a6fa3d6db0d4a0aa6f463afb6b8452))
* add devcontainer for VS Code and GitHub Codespaces ([#133](https://github.com/piers-sinclair/Dostar/issues/133)) ([0360aa4](https://github.com/piers-sinclair/Dostar/commit/0360aa4aada51ba6117e43137fdcb817a5599654))
* add EF Core migration infrastructure and DbContext convention ([#7](https://github.com/piers-sinclair/Dostar/issues/7)) ([a38048a](https://github.com/piers-sinclair/Dostar/commit/a38048a156a737c1284b6e312f1b1c07b05f8225))
* add FluentValidation request validation with shared ValidationFilter&lt;T&gt; ([11b00cc](https://github.com/piers-sinclair/Dostar/commit/11b00ccf688a5369169d370722a1589f6c1fb91f)), closes [#10](https://github.com/piers-sinclair/Dostar/issues/10)
* add global API plumbing (exception handling, correlation IDs, request logging) ([c93329d](https://github.com/piers-sinclair/Dostar/commit/c93329dcb365e95e019a9a5baa0c6bfa9e0ca222))
* add IModule contract and auto-discovery ([#6](https://github.com/piers-sinclair/Dostar/issues/6)) ([5d2f082](https://github.com/piers-sinclair/Dostar/commit/5d2f082df3bdbde8ea9d6a6fe99f1115904e7421))
* add local full-stack dev setup with Docker and Vite proxy ([#4](https://github.com/piers-sinclair/Dostar/issues/4)) ([2602e19](https://github.com/piers-sinclair/Dostar/commit/2602e19039a7f979282553cb487581dde9de6826))
* add module tagging and operationId naming to Todos endpoints ([f0010db](https://github.com/piers-sinclair/Dostar/commit/f0010db62eba9a7fd5cb79026b6aaedff6ebc43c))
* add module tagging and operationId naming to Todos endpoints ([6d4883b](https://github.com/piers-sinclair/Dostar/commit/6d4883b645a94eaf294a5342e83151e55cac0172))
* add multi-stage Dockerfile for backend ([214a6c6](https://github.com/piers-sinclair/Dostar/commit/214a6c66ef7418bfe82e40a032fa9ecab165c55f))
* add multi-stage Dockerfile for backend ([13d6bde](https://github.com/piers-sinclair/Dostar/commit/13d6bde341c3b70df99245e0492397aaaeca9ef9))
* add rate limiting middleware ([df91e22](https://github.com/piers-sinclair/Dostar/commit/df91e22151a325cf3266e9a6a0f09d83c52a62bb))
* add rate limiting middleware ([89fcdbb](https://github.com/piers-sinclair/Dostar/commit/89fcdbb871848a9a6a6bb5d55418a00f3dbe8893)), closes [#47](https://github.com/piers-sinclair/Dostar/issues/47)
* add ReportGenerator HTML coverage report artifact ([d86250f](https://github.com/piers-sinclair/Dostar/commit/d86250f14407bb1c0cf3ccd25bdd4a5c50169d2d))
* add Scalar API reference UI ([#2](https://github.com/piers-sinclair/Dostar/issues/2)) ([0831727](https://github.com/piers-sinclair/Dostar/commit/08317275001e3facdfb84f8ec34b84f15eb35443))
* add security headers middleware ([3d99436](https://github.com/piers-sinclair/Dostar/commit/3d994363cd19340458ec691c5a89dadd70b138db))
* add security headers middleware ([29c25a7](https://github.com/piers-sinclair/Dostar/commit/29c25a70bd39a04d85e1b4ead37b02f152c59b2f)), closes [#48](https://github.com/piers-sinclair/Dostar/issues/48)
* add SharedKernel unit tests and extend coverage script ([#104](https://github.com/piers-sinclair/Dostar/issues/104)) ([971e18b](https://github.com/piers-sinclair/Dostar/commit/971e18b4796c4af03f39465e23304e033edf498e))
* add staticwebapp.config.json for SPA routing ([#144](https://github.com/piers-sinclair/Dostar/issues/144)) ([e633982](https://github.com/piers-sinclair/Dostar/commit/e633982c808a00a5d4762ae27eee79f07f423800)), closes [#51](https://github.com/piers-sinclair/Dostar/issues/51)
* add Todos module — full vertical slice ([#8](https://github.com/piers-sinclair/Dostar/issues/8)) ([1579a29](https://github.com/piers-sinclair/Dostar/commit/1579a29c21a01918a64c5fc5efea2480749bae55))
* add Trivy + Semgrep SAST to CI and harden Roslyn analysis ([1a988eb](https://github.com/piers-sinclair/Dostar/commit/1a988ebd1eaf6a94b6e8ce36e43939ba6e914093))
* add Trivy + Semgrep SAST to CI and harden Roslyn analysis ([c9820d4](https://github.com/piers-sinclair/Dostar/commit/c9820d49228f609d558c3e9a12ef6b4a1874f3f0)), closes [#79](https://github.com/piers-sinclair/Dostar/issues/79)
* add TRX logging, timeouts, and code coverage to CI (closes [#21](https://github.com/piers-sinclair/Dostar/issues/21), closes [#19](https://github.com/piers-sinclair/Dostar/issues/19)) ([69e8c07](https://github.com/piers-sinclair/Dostar/commit/69e8c07459ab2eaeb4682f3a399d767b1100c1e7))
* add URL-based API versioning ([892e2cf](https://github.com/piers-sinclair/Dostar/commit/892e2cf9942d1cd5be2d7a2598e7251598c25c07))
* add URL-based API versioning ([9867b82](https://github.com/piers-sinclair/Dostar/commit/9867b820ad0daf90aa876091c925f095db89dea2)), closes [#46](https://github.com/piers-sinclair/Dostar/issues/46)
* add validator unit tests to improve coverage of implementation layer ([6adc073](https://github.com/piers-sinclair/Dostar/commit/6adc07360ebb40e0361df73c2e88d3316587d07f))
* **agents:** add /create-issue Claude Code skill ([#261](https://github.com/piers-sinclair/Dostar/issues/261)) ([4893bac](https://github.com/piers-sinclair/Dostar/commit/4893bac3c3d4b57a0a61274388d01a83cc5a68d0))
* **agents:** add integration-tests skill ([#228](https://github.com/piers-sinclair/Dostar/issues/228)) ([4a8cd3d](https://github.com/piers-sinclair/Dostar/commit/4a8cd3d8be41324e60528bc9652fec81e9221748))
* **agents:** add Playwright skill and UI test scaffold ([#227](https://github.com/piers-sinclair/Dostar/issues/227)) ([ec9e76e](https://github.com/piers-sinclair/Dostar/commit/ec9e76ef9b986f12f2b32dd33baa60b1b00a0f21)), closes [#35](https://github.com/piers-sinclair/Dostar/issues/35)
* **ai:** add /code-quality audit skill ([#202](https://github.com/piers-sinclair/Dostar/issues/202)) ([b05eb61](https://github.com/piers-sinclair/Dostar/commit/b05eb6106a750d59f62d52256ed4c06fd121a0c9))
* Bicep infra folder structure and resource naming convention ([#143](https://github.com/piers-sinclair/Dostar/issues/143)) ([a5468f9](https://github.com/piers-sinclair/Dostar/commit/a5468f91e648f7d7d02a2e43368e907148d3ece7))
* Bicep modules for ACR and Container Apps ([#27](https://github.com/piers-sinclair/Dostar/issues/27)) ([#148](https://github.com/piers-sinclair/Dostar/issues/148)) ([8956e29](https://github.com/piers-sinclair/Dostar/commit/8956e2928a2b423172917256dd450094071086c2))
* Bicep what-if check on infra PR changes ([#164](https://github.com/piers-sinclair/Dostar/issues/164)) ([a2ecb38](https://github.com/piers-sinclair/Dostar/commit/a2ecb382fa16952da75110d8e2d19d810e51b2f2))
* bootstrap React + Vite + TypeScript frontend ([8d43df1](https://github.com/piers-sinclair/Dostar/commit/8d43df14b5b1c1c3108002bb159369c2da15437d))
* bootstrap React + Vite + TypeScript frontend ([#3](https://github.com/piers-sinclair/Dostar/issues/3)) ([c025744](https://github.com/piers-sinclair/Dostar/commit/c025744361041c8c36fd253ee092be7c0ba1517f))
* **cd:** add frontend deploy workflow for Static Web Apps (dev) ([#193](https://github.com/piers-sinclair/Dostar/issues/193)) ([ee7797c](https://github.com/piers-sinclair/Dostar/commit/ee7797c412cecac631b285168a2c6faec46abc69))
* **cd:** add path filters to backend and frontend deploy workflows ([#192](https://github.com/piers-sinclair/Dostar/issues/192)) ([f84f802](https://github.com/piers-sinclair/Dostar/commit/f84f8026dd444cb9f87c93621bdb7f88690397ba))
* **ci:** add dev environment lifecycle workflows and docs ([#205](https://github.com/piers-sinclair/Dostar/issues/205)) ([61032e0](https://github.com/piers-sinclair/Dostar/commit/61032e0fd629a782a9d93f09fffbe3495c3f363d))
* **ci:** add environment input to all CD and infra workflows ([#231](https://github.com/piers-sinclair/Dostar/issues/231)) ([7e8ce22](https://github.com/piers-sinclair/Dostar/commit/7e8ce2247cebf851e64cc8ac2504b48fafd65817)), closes [#24](https://github.com/piers-sinclair/Dostar/issues/24)
* **ci:** add environment URL summaries to deploy workflows ([#221](https://github.com/piers-sinclair/Dostar/issues/221)) ([8d525f0](https://github.com/piers-sinclair/Dostar/commit/8d525f09b513a5d0a843ff3750ae82ef8713dd30))
* **ci:** route SWA deployment token through Key Vault ([#220](https://github.com/piers-sinclair/Dostar/issues/220)) ([3e8ae3c](https://github.com/piers-sinclair/Dostar/commit/3e8ae3c0191a717df5abe590021d38bbf7b12048)), closes [#216](https://github.com/piers-sinclair/Dostar/issues/216)
* configure CORS for dev and production environments ([b707357](https://github.com/piers-sinclair/Dostar/commit/b7073577aba96216f4b4ab989ea28785396ffdf3))
* configure CORS for dev and production environments ([6cea6f6](https://github.com/piers-sinclair/Dostar/commit/6cea6f690e094205ee5a6c366221d07e3c7a2609)), closes [#45](https://github.com/piers-sinclair/Dostar/issues/45)
* **dx:** install Claude Code CLI and improve terminal experience in devcontainer ([#218](https://github.com/piers-sinclair/Dostar/issues/218)) ([1b5c798](https://github.com/piers-sinclair/Dostar/commit/1b5c798f30809703b06f945a56946daa317143d3)), closes [#217](https://github.com/piers-sinclair/Dostar/issues/217)
* EF Core migration infrastructure and DbContext convention ([ab71241](https://github.com/piers-sinclair/Dostar/commit/ab712418ff91468fbb1deefe40e77bc2e87b7040))
* enforce 80% coverage threshold on unit tests ([bcd0c01](https://github.com/piers-sinclair/Dostar/commit/bcd0c01e365a99a5162f8d6d1c23e439c0a051de))
* enforce 80% line coverage threshold on integration tests ([5f14493](https://github.com/piers-sinclair/Dostar/commit/5f14493943b42d0f2d690136ecf1e0614dc21e33))
* enforce coverage threshold via coverlet.console CLI ([6235ac4](https://github.com/piers-sinclair/Dostar/commit/6235ac49e6ad2f2c1b1d08cb783f35050ca38cda))
* establish unit test pattern for modules (issue [#16](https://github.com/piers-sinclair/Dostar/issues/16)) ([88dea70](https://github.com/piers-sinclair/Dostar/commit/88dea70047df85c443ba37371d0127d3d67ff357))
* exclude untestable code from coverage via ExcludeFromCodeCoverage ([69f3b23](https://github.com/piers-sinclair/Dostar/commit/69f3b238a153b979246587c25bf06035fff04908))
* exclude validators from coverage, delete validator tests ([011fb81](https://github.com/piers-sinclair/Dostar/commit/011fb8122ffc8e73965756859ccae60de4ba38d8))
* extend health checks with liveness and readiness probes ([2654c5b](https://github.com/piers-sinclair/Dostar/commit/2654c5b4160971b0131d207abe1553c4a7a8ade2))
* extend health checks with liveness and readiness probes ([3cae770](https://github.com/piers-sinclair/Dostar/commit/3cae770f148536e04cc6620455959d1f87bd2691)), closes [#49](https://github.com/piers-sinclair/Dostar/issues/49)
* fail Trivy on any CVE severity; add suppression escape hatches ([5374990](https://github.com/piers-sinclair/Dostar/commit/53749908390704554c079b871f5c4b1e01891a00))
* **frontend:** add orval for type-safe generated API client ([#235](https://github.com/piers-sinclair/Dostar/issues/235)) ([311d574](https://github.com/piers-sinclair/Dostar/commit/311d574510747fd1cd6fe8517b4cad6bc4700de7)), closes [#55](https://github.com/piers-sinclair/Dostar/issues/55)
* **frontend:** add React Hook Form + Zod for form validation ([#234](https://github.com/piers-sinclair/Dostar/issues/234)) ([2b8d55d](https://github.com/piers-sinclair/Dostar/commit/2b8d55d42fbb2f308ba3d75e9e1bbd5632ed4298)), closes [#54](https://github.com/piers-sinclair/Dostar/issues/54)
* **frontend:** add Tailwind v4 + shadcn/ui component library ([#232](https://github.com/piers-sinclair/Dostar/issues/232)) ([1c2ea54](https://github.com/piers-sinclair/Dostar/commit/1c2ea54a71be043272315ab3787a4a0d0e57aedd))
* **frontend:** add TanStack Query for server state management ([#233](https://github.com/piers-sinclair/Dostar/issues/233)) ([50158cd](https://github.com/piers-sinclair/Dostar/commit/50158cd038256c033207f839faf02561e6b186ee))
* **frontend:** inline title editing for todos (Closes [#74](https://github.com/piers-sinclair/Dostar/issues/74)) ([#259](https://github.com/piers-sinclair/Dostar/issues/259)) ([554a0a9](https://github.com/piers-sinclair/Dostar/commit/554a0a90c2e9273b98ca3f0fc4d5cb5fad82c896))
* **frontend:** treat ESLint warnings as errors in lint and build ([#239](https://github.com/piers-sinclair/Dostar/issues/239)) ([4de69e9](https://github.com/piers-sinclair/Dostar/commit/4de69e9920e61288e95355f8aee2543ae61d582b))
* **frontend:** wire VITE_API_BASE_URL for local dev and production ([#246](https://github.com/piers-sinclair/Dostar/issues/246)) ([bc2e255](https://github.com/piers-sinclair/Dostar/commit/bc2e2558af63b262d11e46436ee0143c306ef8ae))
* full-stack Playwright E2E CI workflow ([#176](https://github.com/piers-sinclair/Dostar/issues/176)) ([f09d928](https://github.com/piers-sinclair/Dostar/commit/f09d9289db5c0a20c95eafeb957a8b0a65824b7b))
* global API plumbing — exception handling, correlation IDs, request logging ([aba0424](https://github.com/piers-sinclair/Dostar/commit/aba0424e1efcd170b178f460535d986ab4e4b345))
* IModule contract and auto-discovery ([ca2eed1](https://github.com/piers-sinclair/Dostar/commit/ca2eed11c8e1fe194f56a8e196fdcdc9cb23f4fd))
* **infra:** expose container and postgres sizing as params for prod tuning ([#272](https://github.com/piers-sinclair/Dostar/issues/272)) ([8cd0b42](https://github.com/piers-sinclair/Dostar/commit/8cd0b421c7f4fce6d33a8f85f3d245fcdf081117))
* **infra:** require AZURE_POSTGRES_ADMIN_PASSWORD — remove Placeholder123! fallback ([#247](https://github.com/piers-sinclair/Dostar/issues/247)) ([32a40ee](https://github.com/piers-sinclair/Dostar/commit/32a40ee4336c36602d5ceef437607346b3d3b339))
* **infra:** set ASPNETCORE_ENVIRONMENT=Development in dev to enable Scalar ([#238](https://github.com/piers-sinclair/Dostar/issues/238)) ([1624fc4](https://github.com/piers-sinclair/Dostar/commit/1624fc46eba62a6de433cdcf000e2557ad74c526))
* initialise .NET solution and Dostar.Api ([#2](https://github.com/piers-sinclair/Dostar/issues/2)) ([23fe096](https://github.com/piers-sinclair/Dostar/commit/23fe0965a10956a11175662ae28c1dd41d00cb62))
* initialise .NET solution and Dostar.Api ([#2](https://github.com/piers-sinclair/Dostar/issues/2)) ([0a626a2](https://github.com/piers-sinclair/Dostar/commit/0a626a2f17094e3dfa7405ec83afe237b9c59799))
* integration test project with WebApplicationFactory and Testcontainers (issue [#17](https://github.com/piers-sinclair/Dostar/issues/17)) ([e7dd5dc](https://github.com/piers-sinclair/Dostar/commit/e7dd5dcdd13408a1da95edecc1d833a12c13ae1b))
* local full-stack dev setup with Docker and Vite proxy ([cdee542](https://github.com/piers-sinclair/Dostar/commit/cdee54200950591c53144606b09de938f138734a))
* move CLI to dedicated Dostar.Cli repo ([#142](https://github.com/piers-sinclair/Dostar/issues/142)) ([cab01da](https://github.com/piers-sinclair/Dostar/commit/cab01daf798e114aab32602aef2a2e13959f1994))
* Playwright E2E test project ([#103](https://github.com/piers-sinclair/Dostar/issues/103)) ([77b52ab](https://github.com/piers-sinclair/Dostar/commit/77b52ab8c6b168ba4fa2d4355177846102a91967))
* replace per-module CI steps with auto-discovery script ([9f79050](https://github.com/piers-sinclair/Dostar/commit/9f7905008b56137b8bb08c3224729d2427662fb2)), closes [#97](https://github.com/piers-sinclair/Dostar/issues/97)
* replace per-module CI test steps with auto-discovery script ([7b29d33](https://github.com/piers-sinclair/Dostar/commit/7b29d339240c45ee96642ae025298076334d5f28))
* replace startup migrations with dedicated migration job in CD ([#230](https://github.com/piers-sinclair/Dostar/issues/230)) ([e7a60e1](https://github.com/piers-sinclair/Dostar/commit/e7a60e19e4b4a3631912568f49bac43a8507116b))
* request validation with FluentValidation ([#10](https://github.com/piers-sinclair/Dostar/issues/10)) ([8566edc](https://github.com/piers-sinclair/Dostar/commit/8566edc9f6d6ad377cad696fd4a30466b4bcc9d4))
* **skills:** add /audit-azure-costs Claude skill ([#201](https://github.com/piers-sinclair/Dostar/issues/201)) ([8432b1f](https://github.com/piers-sinclair/Dostar/commit/8432b1f0707f92e76454824cac36859862ad679e))
* Todos module — full vertical slice ([#8](https://github.com/piers-sinclair/Dostar/issues/8)) ([b80c34a](https://github.com/piers-sinclair/Dostar/commit/b80c34a560e9342d2fff9073627f083a48b27ca0))
* TRX logging, timeouts, and code coverage reporting in CI ([2ba1494](https://github.com/piers-sinclair/Dostar/commit/2ba14943d38de7d4e2ba1d2f6a496dd7c0e4a2f3))
* unit test pattern per module ([d066d5c](https://github.com/piers-sinclair/Dostar/commit/d066d5c097f7ccc22d1038a4e97fb093a5c3a221))


### Bug Fixes

* add final newline and extract magic strings in rate limiter ([d569c0e](https://github.com/piers-sinclair/Dostar/commit/d569c0e75e9d66ca33a8ad9a311abaad4b169fee))
* add final newline to SecurityHeadersMiddleware ([85db1c4](https://github.com/piers-sinclair/Dostar/commit/85db1c4a8a1c6e800385e713fa8dd15e23ddb345))
* add final newlines to Program.cs and TodosModule.cs ([9925eb3](https://github.com/piers-sinclair/Dostar/commit/9925eb34b9f11635b56a0acf862e470a82307a3a))
* apply Prettier formatting to existing frontend files ([2ea5f63](https://github.com/piers-sinclair/Dostar/commit/2ea5f633dc5b307cb82c67ca3a1bbe7148a6674a))
* **cd:** configure ACR registry identity on container app update ([#187](https://github.com/piers-sinclair/Dostar/issues/187)) ([b6f542b](https://github.com/piers-sinclair/Dostar/commit/b6f542b6d4ade733a4f72bc7a6235044c0366db2))
* **cd:** point SWA deploy at frontend/dist to avoid uploading node_modules ([#198](https://github.com/piers-sinclair/Dostar/issues/198)) ([7f4a751](https://github.com/piers-sinclair/Dostar/commit/7f4a7515770c04fdb4024e3f4e37fa70fa746ab2))
* **cd:** remove invalid flags from az containerapp update ([#189](https://github.com/piers-sinclair/Dostar/issues/189)) ([fe8b78f](https://github.com/piers-sinclair/Dostar/commit/fe8b78f6e641525cc8bb804351fab27931150452))
* **cd:** restore NuGet packages before running EF migrations ([#260](https://github.com/piers-sinclair/Dostar/issues/260)) ([5140e67](https://github.com/piers-sinclair/Dostar/commit/5140e67a382b760a8cfb59d3f8d53471089156ce))
* **cd:** run EF migrations inside VNet via Container Apps Job ([#262](https://github.com/piers-sinclair/Dostar/issues/262)) ([8d65abd](https://github.com/piers-sinclair/Dostar/commit/8d65abd79fb6af797e4475a04821dcd8155aefd9))
* **cd:** skip Oryx app build in SWA deploy — use pre-built dist instead ([#197](https://github.com/piers-sinclair/Dostar/issues/197)) ([1efdd40](https://github.com/piers-sinclair/Dostar/commit/1efdd406fd63b87be286aa4a693ca10f207c3240))
* **cd:** use az containerapp registry set instead of invalid update flags ([#188](https://github.com/piers-sinclair/Dostar/issues/188)) ([8ba580a](https://github.com/piers-sinclair/Dostar/commit/8ba580a5502b78b96df16170c81b0a4ede6b3365))
* **cd:** use repo-root build context for Docker build ([#184](https://github.com/piers-sinclair/Dostar/issues/184)) ([c1a0ab4](https://github.com/piers-sinclair/Dostar/commit/c1a0ab4813140cdda2039481f17342cfb7f01171))
* **ci:** add environment:dev OIDC federated credential for CD workflows ([#236](https://github.com/piers-sinclair/Dostar/issues/236)) ([e825fe6](https://github.com/piers-sinclair/Dostar/commit/e825fe68c8ab0eabb63780eeff936ac6d2b38a44))
* **ci:** hardcode resource group name in teardown — remove RESOURCE_GROUP secret ([#209](https://github.com/piers-sinclair/Dostar/issues/209)) ([ac7921c](https://github.com/piers-sinclair/Dostar/commit/ac7921c2f0eff96877a88c69b02a17e14c76233b))
* **ci:** remove env suffix from OIDC name and fix hardcoded dev values ([#271](https://github.com/piers-sinclair/Dostar/issues/271)) ([9a85e01](https://github.com/piers-sinclair/Dostar/commit/9a85e01fd075218f71c4df1e91d15b04c5024a07))
* **ci:** remove environment key from teardown to stop showing 'Deploying to xxx' ([#278](https://github.com/piers-sinclair/Dostar/issues/278)) ([6bb13b9](https://github.com/piers-sinclair/Dostar/commit/6bb13b98f72140422ca6ecc0f921fbd0c1640465))
* **ci:** remove federated credential step from bootstrap-rbac ([#237](https://github.com/piers-sinclair/Dostar/issues/237)) ([bf8b22a](https://github.com/piers-sinclair/Dostar/commit/bf8b22ab3b9083b4097a7999eb4eb5df8f2b6b46))
* **ci:** restore AZURE_POSTGRES_ADMIN_PASSWORD in infra-deploy ([#268](https://github.com/piers-sinclair/Dostar/issues/268)) ([e81f291](https://github.com/piers-sinclair/Dostar/commit/e81f29102b59e671f2d120217c15e4ec7acc099f))
* **ci:** use parameterised deployment name in infra-deploy ([#281](https://github.com/piers-sinclair/Dostar/issues/281)) ([362767f](https://github.com/piers-sinclair/Dostar/commit/362767fe9778f446f083422e062a600f2e0fac13))
* **ci:** wait for resource group deletion in teardown workflow ([#210](https://github.com/piers-sinclair/Dostar/issues/210)) ([755124d](https://github.com/piers-sinclair/Dostar/commit/755124dad613206aee93409d12949bb4b2183622))
* **devcontainer:** persist Claude auth config across container rebuilds ([#241](https://github.com/piers-sinclair/Dostar/issues/241)) ([620046e](https://github.com/piers-sinclair/Dostar/commit/620046eb0f91c6ecbdbe7cd972bbadcc4463fbab))
* **devcontainer:** retry docker network connect after compose up ([52a3301](https://github.com/piers-sinclair/Dostar/commit/52a3301a416c036901714303b23970a1bbd6105b))
* **docker:** include tools/ in build context for migrator stage ([#263](https://github.com/piers-sinclair/Dostar/issues/263)) ([289657e](https://github.com/piers-sinclair/Dostar/commit/289657ea03cd1fbb60f2edc5d470ecf48aa9f383))
* **docker:** simplify build — single COPY + publish, no per-project restore ([#185](https://github.com/piers-sinclair/Dostar/issues/185)) ([d183c65](https://github.com/piers-sinclair/Dostar/commit/d183c65eea3073ea7d85ef7291f9da24c7d06dfc))
* drop ReportGenerator, upload raw coverage XML as artifact ([f01f5d2](https://github.com/piers-sinclair/Dostar/commit/f01f5d2b80e54900cc6f23d66550ef87691075f0))
* enforce coverage threshold via Python script, revert TRX to failure-only ([38e9cec](https://github.com/piers-sinclair/Dostar/commit/38e9cec8464ff8217f003670f1d81c0b3c62006e))
* exclude host and shared kernel assemblies from coverage threshold ([8b0030e](https://github.com/piers-sinclair/Dostar/commit/8b0030e540cfabd5ea9ff70eaf86a9bb6f98300a))
* explicitly set non-root USER in Dockerfile (Semgrep finding) ([c0cbc0b](https://github.com/piers-sinclair/Dostar/commit/c0cbc0b2c9d745f6ed9ed7b65b090a9cfd6e1466))
* extract magic strings in security headers middleware ([b00490f](https://github.com/piers-sinclair/Dostar/commit/b00490f450617de4700d49b16c28227cbdd58b63))
* extract magic strings, move Asp.Versioning to global usings, drop docs ([ba03ed1](https://github.com/piers-sinclair/Dostar/commit/ba03ed10f65a1b736aaa49029d828ca85c638f39))
* fail early with clear message when Azure secrets are missing ([#166](https://github.com/piers-sinclair/Dostar/issues/166)) ([2bf69dd](https://github.com/piers-sinclair/Dostar/commit/2bf69dd09d66cb36c62626cd36efd350a9ae0c1a))
* **frontend:** fix toggle 400, add create input, fix deployed CORS ([#251](https://github.com/piers-sinclair/Dostar/issues/251)) ([ca6e61c](https://github.com/piers-sinclair/Dostar/commit/ca6e61ceeaa4674cadda175d392ceefb47ae1532))
* **frontend:** optimistic updates, shadcn Checkbox, and 204 DELETE fix ([#252](https://github.com/piers-sinclair/Dostar/issues/252)) ([45c25c4](https://github.com/piers-sinclair/Dostar/commit/45c25c46c43c5bd82627648c14fc2f56fe1ee8de))
* **infra:** disable PostgreSQL HA by default, make it opt-in ([#277](https://github.com/piers-sinclair/Dostar/issues/277)) ([6cf3061](https://github.com/piers-sinclair/Dostar/commit/6cf30613713cd3e6413cf53de67d12aa8dcbe1d4))
* **infra:** pass connection string as secure param instead of KV reference ([#194](https://github.com/piers-sinclair/Dostar/issues/194)) ([3f64ef2](https://github.com/piers-sinclair/Dostar/commit/3f64ef2c0cbf76ed2f0da283a66fc6a260e6671e))
* **infra:** pass SWA hostname to Container App as CORS allowed origin ([#249](https://github.com/piers-sinclair/Dostar/issues/249)) ([9506f50](https://github.com/piers-sinclair/Dostar/commit/9506f50b027a6d6952cf9fe8c8060fcf56876a10))
* **infra:** use readEnvironmentVariable for prod postgres password ([#275](https://github.com/piers-sinclair/Dostar/issues/275)) ([3cabe6a](https://github.com/piers-sinclair/Dostar/commit/3cabe6a8bc8224807ea681fd099b4edbddf92ac6))
* **infra:** wire PostgreSQL connection string from Key Vault into Container App ([#191](https://github.com/piers-sinclair/Dostar/issues/191)) ([b190ff5](https://github.com/piers-sinclair/Dostar/commit/b190ff5d7d38772c4862becdfe7c2a8c3d365022)), closes [#163](https://github.com/piers-sinclair/Dostar/issues/163)
* install OpenGrep binary directly to PATH instead of using install.sh ([be614d0](https://github.com/piers-sinclair/Dostar/commit/be614d0d0196d55601090cdb9963d24a79785b28))
* install OpenGrep via binary release script (no official Docker image) ([9e304a0](https://github.com/piers-sinclair/Dostar/commit/9e304a0fd3dd29f318c7167de510774faeaa191e))
* install ReportGenerator to local tool path instead of globally ([aa191ad](https://github.com/piers-sinclair/Dostar/commit/aa191ad0b858a5d62fe3f6001ea962a01a13c730))
* move coverage threshold to runsettings, use ReportGenerator action ([53da3a4](https://github.com/piers-sinclair/Dostar/commit/53da3a4de372483899cf34ef975c9a2e21b11276))
* RBAC bootstrap SP object ID, rename deploy docs, remove azd issue ([#182](https://github.com/piers-sinclair/Dostar/issues/182)) ([8ccde06](https://github.com/piers-sinclair/Dostar/commit/8ccde06db230f5e4b5b5bf0d4d34db219863d082))
* **rbac:** assign Container App managed identity AcrPull; fix CI SP to AcrPush ([#186](https://github.com/piers-sinclair/Dostar/issues/186)) ([80b963d](https://github.com/piers-sinclair/Dostar/commit/80b963d4e97b844f8083d2a3c25a752860ec7546))
* remove --error from opengrep ci (ci subcommand fails on findings by default) ([1a938b3](https://github.com/piers-sinclair/Dostar/commit/1a938b31f9098a1bb1e65866499cf142538a7290))
* remove BOM from EF Core generated migration files ([1929ed8](https://github.com/piers-sinclair/Dostar/commit/1929ed863fcbee5635e47221c7e26bf9ff8d1636))
* remove newGuid() default from postgresAdminPassword ([#162](https://github.com/piers-sinclair/Dostar/issues/162)) ([373d24b](https://github.com/piers-sinclair/Dostar/commit/373d24bc7f5586c65de8ad8899a782733fab0860))
* rename workflows to ci/cd+env convention, fix cd-dev deploy flow ([#183](https://github.com/piers-sinclair/Dostar/issues/183)) ([bbb3421](https://github.com/piers-sinclair/Dostar/commit/bbb342127c5c94c311d7d453750afb0a1b47ae3b)), closes [#158](https://github.com/piers-sinclair/Dostar/issues/158)
* replace eslint-plugin-react with react-x/react-dom for ESLint 10 compatibility ([c5b9c5b](https://github.com/piers-sinclair/Dostar/commit/c5b9c5bc01f42c43e7121546e5ceeed07d418f4c))
* replace trivy-action with direct apt install to fix CI download failure ([c3c304a](https://github.com/piers-sinclair/Dostar/commit/c3c304aa03de694198a74b0efc5c94f78a8de1d2))
* resolve infra first-deploy failures ([#160](https://github.com/piers-sinclair/Dostar/issues/160)) ([5798c86](https://github.com/piers-sinclair/Dostar/commit/5798c86353432c03e23197dabf0b09a017a09a66))
* run EF Core migrations at startup for all modules ([#195](https://github.com/piers-sinclair/Dostar/issues/195)) ([18ccfe9](https://github.com/piers-sinclair/Dostar/commit/18ccfe97bd694a27750d29efc5ba097468dcecb8))
* scope integration test coverage to Todos module via --include ([7320cfa](https://github.com/piers-sinclair/Dostar/commit/7320cfac775214eed0a3b56d9284513d263fd79b))
* scope unit test coverage to application layer only ([6443a92](https://github.com/piers-sinclair/Dostar/commit/6443a924f1eae04c88de30745987f53388f84e29))
* skip CSP in dev so Scalar renders, fix healthz URL ([#102](https://github.com/piers-sinclair/Dostar/issues/102)) ([908c53b](https://github.com/piers-sinclair/Dostar/commit/908c53b1b83f1412b2858b2b1df53c8e04063e6d))
* update CI to use new test project paths ([920ee66](https://github.com/piers-sinclair/Dostar/commit/920ee6614bd85fd3adb48d76be7fa4da621aa2bb))
* update global.json to .NET SDK 10.0.200 ([d0ea616](https://github.com/piers-sinclair/Dostar/commit/d0ea616cce8d408ee3428870f094ec2e21b0bc40))
* update global.json to .NET SDK 10.0.200 ([35e0731](https://github.com/piers-sinclair/Dostar/commit/35e0731b1432535adf7910bcd70230bec3d24838))
* upload test results on every run, not just on failure ([c703fa7](https://github.com/piers-sinclair/Dostar/commit/c703fa7453b8a570956b9824ada6d119b71a7f0a))
* use message-template BeginScope for readable CorrelationId in console logs ([6004ade](https://github.com/piers-sinclair/Dostar/commit/6004ade9568aab8bb2cc0016a17295aea5821da9))


### Documentation

* add CLAUDE.md ([#34](https://github.com/piers-sinclair/Dostar/issues/34)) ([5f70a34](https://github.com/piers-sinclair/Dostar/commit/5f70a3403dce3c68f57ed7c4a825674def955fa5))
* add CLAUDE.md maintenance reminder ([#34](https://github.com/piers-sinclair/Dostar/issues/34)) ([f931279](https://github.com/piers-sinclair/Dostar/commit/f9312792262390412e483cefecc277ce8bb8f8fa))
* add CLAUDE.md maintenance reminder ([#34](https://github.com/piers-sinclair/Dostar/issues/34)) ([cfdab1f](https://github.com/piers-sinclair/Dostar/commit/cfdab1f74c5bb4c8a304c8a9f5486505223cc1e8))
* add CLAUDE.md with project context for Claude Code sessions ([6da1adc](https://github.com/piers-sinclair/Dostar/commit/6da1adc2e7a97e9c9c908ccb0f4e4adb33e74687))
* add clear onboarding story for rename + Todos removal ([#254](https://github.com/piers-sinclair/Dostar/issues/254)) ([#279](https://github.com/piers-sinclair/Dostar/issues/279)) ([2d188d0](https://github.com/piers-sinclair/Dostar/commit/2d188d04d5b63d838fe079798989a87e8474f85e))
* add migration step to README quick start ([81c8930](https://github.com/piers-sinclair/Dostar/commit/81c89302b506d7875da36f296a2d4e792ddc9cd3))
* add post-deploy verification steps ([#190](https://github.com/piers-sinclair/Dostar/issues/190)) ([5086f9e](https://github.com/piers-sinclair/Dostar/commit/5086f9eeb95cc822713b55dd4ab9c9a0619ccf97))
* add prod federated credential to deploy-setup.md ([#273](https://github.com/piers-sinclair/Dostar/issues/273)) ([ee9f708](https://github.com/piers-sinclair/Dostar/commit/ee9f7085eb91496f24ab7232b26230cfc370cf12))
* add tear-down command and zone-redundant HA guide ([#152](https://github.com/piers-sinclair/Dostar/issues/152)) ([e308127](https://github.com/piers-sinclair/Dostar/commit/e3081278186474c522dda452e0f7b728a1a880f2)), closes [#33](https://github.com/piers-sinclair/Dostar/issues/33)
* **auth:** document authentication approach and options ([#248](https://github.com/piers-sinclair/Dostar/issues/248)) ([cb9dc05](https://github.com/piers-sinclair/Dostar/commit/cb9dc055abdc1e9ea60f0cdd46b151737b572427))
* Azure Container Apps scaling and cost guide ([#150](https://github.com/piers-sinclair/Dostar/issues/150)) ([f6180df](https://github.com/piers-sinclair/Dostar/commit/f6180dfb04d0d1b6bd2de6b74504ca70e7e9716c))
* CI/CD setup guide for azd pipeline config ([#180](https://github.com/piers-sinclair/Dostar/issues/180)) ([415e97d](https://github.com/piers-sinclair/Dostar/commit/415e97d6f133a1d4da5cd5ed6ac3c3f9b37afe58))
* **ci:** document GitHub Actions PR creation setting for Release Please ([#274](https://github.com/piers-sinclair/Dostar/issues/274)) ([d67bb4e](https://github.com/piers-sinclair/Dostar/commit/d67bb4ec67aa5293f9e14f3f45e2fa2a34ad0660))
* clarify worktree cleanup — add branch delete and stale prune steps ([#267](https://github.com/piers-sinclair/Dostar/issues/267)) ([1648089](https://github.com/piers-sinclair/Dostar/commit/1648089cfdebaadcad0116398be141791663de8e))
* define and document CLI packaging and publishing story ([#269](https://github.com/piers-sinclair/Dostar/issues/269)) ([1a283a0](https://github.com/piers-sinclair/Dostar/commit/1a283a0dc19677f2e63eab8538e7c8369fe6e409))
* document test organisation decision in module-pattern.md ([6186cd5](https://github.com/piers-sinclair/Dostar/commit/6186cd56cdb0814e4d262de2ab75cc3565fc32a8))
* document test organisation in module-pattern.md ([522bb93](https://github.com/piers-sinclair/Dostar/commit/522bb9300e8b3b672b5ddabb9b7eaa16330c9cee))
* expand CONTRIBUTING.md and improve PR template ([#223](https://github.com/piers-sinclair/Dostar/issues/223)) ([cd7ebe6](https://github.com/piers-sinclair/Dostar/commit/cd7ebe6324b4753d0ae0ea17adaaa5d847e8bcd6))
* expand README with architecture, stack, skills, and deploy sections ([#225](https://github.com/piers-sinclair/Dostar/issues/225)) ([c29570e](https://github.com/piers-sinclair/Dostar/commit/c29570e328e1ab6cbe93b1d2778607dcc8000476)), closes [#38](https://github.com/piers-sinclair/Dostar/issues/38)
* move CORS docs to CLAUDE.md, remove development.md ([daf36a3](https://github.com/piers-sinclair/Dostar/commit/daf36a3feeb83992b742a3ef5fd95390ebb2b0a7))
* require git worktrees for all agentic AI changes ([#206](https://github.com/piers-sinclair/Dostar/issues/206)) ([9ec41b8](https://github.com/piers-sinclair/Dostar/commit/9ec41b8dd1405ba2c2abdb66583a9198cb5bc1e4))
* state code-first migration convention explicitly ([a3b8369](https://github.com/piers-sinclair/Dostar/commit/a3b83698517765822bf3a66d2771cc1ebec30bfd))
* use single-line commands to support PowerShell ([47df799](https://github.com/piers-sinclair/Dostar/commit/47df7991eaf86ced09b3d86dd86f78f6fba0e5c0))

## Changelog

All notable changes to this project will be documented in this file. See [release-please](https://github.com/googleapis/release-please) for commit guidelines.
