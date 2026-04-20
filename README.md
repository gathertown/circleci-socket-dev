# CircleCI Socket.dev orb

Reusable CircleCI configuration for [Socket.dev](https://socket.dev) in CircleCI. You can run [`socket ci`](https://docs.socket.dev/docs/socket-ci) for org policy enforcement, [Socket Firewall Free](https://docs.socket.dev/docs/socket-firewall-free) (`npx sfw`) or [Socket Firewall Enterprise](https://docs.socket.dev/docs/socket-firewall-enterprise) (official `sfw` binary and `SOCKET_API_KEY`) to filter package-manager traffic, or both. The `scan` job uses **`mode`** (`ci`, `sfw`, or `both`; default `ci`) and **`sfw_edition`** (`free` or `enterprise`) when running the firewall step.

Version history: [CHANGELOG.md](CHANGELOG.md).

## Requirements

- CircleCI configuration **version 2.1**
- For **`mode: ci`** or **`mode: both`**: a [Socket.dev](https://socket.dev) organization and a CI API token with the scopes described in [Create Socket API Key for CI/CD](https://docs.socket.dev/docs/create-socket-api-key-for-cicd)
- For **`sfw_edition: free`** (default): no API key; the `sfw` npm wrapper runs via `npx` ([Socket Firewall Free](https://docs.socket.dev/docs/socket-firewall-free)).
- For **`sfw_edition: enterprise`**: a Socket API key in **`SOCKET_API_KEY`** with scopes **`packages`** and **`entitlements:list`**, or a committed **`.sfw.config`** in the app directory ([Enterprise configuration](https://docs.socket.dev/docs/socket-firewall-enterprise-configuration), [wrapper mode](https://docs.socket.dev/docs/socket-firewall-enterprise-wrapper-mode)).
- The [CircleCI CLI](https://circleci.com/docs/guides/local-cli/) if you pack or validate the orb locally (`circleci orb pack`, `circleci orb validate`)

## Authentication

When the job runs **`socket ci`** (`mode: ci` or `mode: both`), **`SOCKET_CLI_API_TOKEN`** must be set in the environment. Typical approaches:

| Approach | Notes |
| -------- | ----- |
| **Project settings** | Environment Variables → add `SOCKET_CLI_API_TOKEN` (mark sensitive). |
| **Context** | Define the variable on a Context and attach `context: <name>` to the job. Preferred for sharing secrets across projects. |

For **Socket Firewall Enterprise** (`sfw_edition: enterprise`), add **`SOCKET_API_KEY`** the same way (scopes **`packages`** and **`entitlements:list`**). You can use a separate Context or the same project as `SOCKET_CLI_API_TOKEN`.

Optional:

- **`SOCKET_CLI_ORG_SLUG`** — Use when your token applies to more than one Socket organization, or you need to pin a specific org. You can also set this with the orb parameter `org_slug` on the `ci` command or `scan` job.

Other variables (for example `SOCKET_CLI_GITHUB_TOKEN` / `GITHUB_TOKEN` if the CLI must reach GitHub) follow the [Socket CLI](https://docs.socket.dev/docs/socket-cli) behavior; set them as project or Context variables as needed.

For **`mode: sfw`** with **`sfw_edition: free`**, no Socket token is required.

## Installation

Declare the orb in `.circleci/config.yml` (pin the version your project should use):

```yaml
version: 2.1

orbs:
  socket: gathertown/socket@1.0.0
```

## Usage

### Job: `scan`

Runs `checkout`, then steps determined by **`mode`**:

| `mode` | Behavior |
| ------ | -------- |
| `ci` (default) | `socket ci` only (requires `SOCKET_CLI_API_TOKEN`). |
| `sfw` | Socket Firewall only: `npx sfw@…` (Free) or Enterprise binary (see `sfw_edition`). |
| `both` | `sfw` first, then `socket ci` (`SOCKET_CLI_API_TOKEN` required for the scan; Enterprise firewall also needs `SOCKET_API_KEY` when `sfw_edition: enterprise`). |

```yaml
workflows:
  security:
    jobs:
      - socket/scan:
          context: socket-credentials
```

Minimal configuration for **`mode: ci`**: a Context (or project env) that defines `SOCKET_CLI_API_TOKEN`.

Firewall-only example:

```yaml
workflows:
  install:
    jobs:
      - socket/scan:
          mode: sfw
```

Install through the firewall, then policy scan:

```yaml
workflows:
  supply-chain:
    jobs:
      - socket/scan:
          mode: both
          context: socket-credentials
```

### Command: `ci`

Use inside your own jobs when you already control checkout, caching, or need custom steps before the scan.

```yaml
jobs:
  analyze:
    executor: socket/default
    steps:
      - checkout
      - run: npm ci
      - socket/ci:
          cli_version: latest
          app_dir: packages/my-app
```

### Command: `sfw`

Use when you control checkout and other steps but want installs (or any supported package-manager command) wrapped with Socket Firewall. Set **`sfw_edition: free`** (default) for [Socket Firewall Free](https://docs.socket.dev/docs/socket-firewall-free) via `npx`, or **`sfw_edition: enterprise`** for [Socket Firewall Enterprise](https://docs.socket.dev/docs/socket-firewall-enterprise) (downloads the Linux binary from [firewall-release](https://github.com/SocketDev/firewall-release); provide **`SOCKET_API_KEY`** on the job or `.sfw.config`).

```yaml
jobs:
  install:
    executor: socket/default
    steps:
      - checkout
      - socket/sfw:
          sfw_command: yarn install --frozen-lockfile
          app_dir: packages/my-app
```

Enterprise example (Context supplies `SOCKET_API_KEY`):

```yaml
      - socket/sfw:
          sfw_edition: enterprise
          sfw_enterprise_version: latest
          sfw_command: npm ci
```

### Executor: `default`

`cimg/node` with a configurable image tag. Use when you author jobs that call `socket/ci` or `socket/sfw` manually.

```yaml
jobs:
  custom:
    executor:
      name: socket/default
      tag: "22.14"
    steps:
      - checkout
      - socket/ci
```

## Parameters

### `commands/ci`

| Parameter | Type | Default | Description |
| --------- | ---- | ------- | ----------- |
| `cli_version` | string | `latest` | npm `socket` package version or dist-tag passed to `npx` (for example `latest` or `1.1.84`). |
| `auto_manifest` | boolean | `false` | If `true`, adds `--autoManifest` so manifests can be generated where the CLI supports it. |
| `app_dir` | string | `.` | Working directory for the scan, relative to the repository root after checkout. |
| `org_slug` | string | `""` | If non-empty, sets `SOCKET_CLI_ORG_SLUG` for this step. |
| `extra_args` | string | `""` | Extra arguments appended to `socket ci` (include a leading space if you pass multiple tokens). |

### `commands/sfw`

| Parameter | Type | Default | Description |
| --------- | ---- | ------- | ----------- |
| `sfw_edition` | enum | `free` | `free`: `npx sfw@…` (Firewall Free). `enterprise`: GitHub release binary + `SOCKET_API_KEY` or `.sfw.config`. |
| `sfw_version` | string | `latest` | npm `sfw` version when `sfw_edition` is `free`. |
| `sfw_enterprise_version` | string | `latest` | Release tag from [firewall-release](https://github.com/SocketDev/firewall-release) when `sfw_edition` is `enterprise`, or `latest`. |
| `sfw_enterprise_musl` | boolean | `false` | When `enterprise`, use the musl Linux build (for example Alpine-like images). |
| `app_dir` | string | `.` | Working directory for the command, relative to the repository root after checkout. |
| `sfw_command` | string | `yarn install --frozen-lockfile` | Arguments after `sfw` (for example `npm ci`, `pnpm install --frozen-lockfile`). |
| `sfw_config_relative_paths` | boolean | `false` | Enterprise: set `SFW_CONFIG_RELATIVE_PATHS`. |
| `sfw_custom_registries` | string | `""` | Enterprise: optional `SFW_CUSTOM_REGISTRIES` value. |
| `sfw_unknown_host_action` | string | `""` | Enterprise: optional `SFW_UNKNOWN_HOST_ACTION` (`block`, `warn`, `ignore`). |
| `sfw_telemetry_disabled` | boolean | `false` | Enterprise: set `SFW_TELEMETRY_DISABLED=true`. |
| `sfw_debug` | boolean | `false` | Enterprise: set `SFW_DEBUG=true`. |

### `jobs/scan`

| Parameter | Type | Default | Description |
| --------- | ---- | ------- | ----------- |
| `mode` | enum | `ci` | `ci`: `socket ci` only. `sfw`: Socket Firewall only. `both`: `sfw` then `socket ci`. |
| `node_tag` | string | `current` | [cimg/node](https://hub.docker.com/r/cimg/node/tags) tag for the Docker executor. |
| `resource_class` | string | `medium` | [CircleCI resource class](https://circleci.com/docs/configuration-reference/#resourceclass) for the job (for example `medium`, `large`, `arm.medium`). |
| `sfw_edition` | enum | `free` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_version` | string | `latest` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_enterprise_version` | string | `latest` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_enterprise_musl` | boolean | `false` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_command` | string | `yarn install --frozen-lockfile` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_config_relative_paths` | boolean | `false` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_custom_registries` | string | `""` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_unknown_host_action` | string | `""` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_telemetry_disabled` | boolean | `false` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |
| `sfw_debug` | boolean | `false` | Passed to `commands/sfw` when `mode` is `sfw` or `both`. |

Forwarded to `ci` when `mode` is `ci` or `both`: `cli_version`, `auto_manifest`, `app_dir`, `org_slug`, `extra_args`.

### `executors/default`

| Parameter | Type | Default | Description |
| --------- | ---- | ------- | ----------- |
| `tag` | string | `current` | `cimg/node` image tag. |

## Examples

### Scan with a Context

```yaml
version: 2.1

orbs:
  socket: gathertown/socket@1.0.0

workflows:
  supply-chain:
    jobs:
      - socket/scan:
          context: socket-dev-credentials
```

### Monorepo subdirectory

```yaml
- socket/scan:
    context: socket-dev-credentials
    app_dir: services/api
    auto_manifest: true
```

### Custom job with explicit Node image

```yaml
jobs:
  socket-policy:
    executor:
      name: socket/default
      tag: lts
    steps:
      - checkout
      - socket/ci

workflows:
  security:
    jobs:
      - socket-policy:
          context: socket-dev-credentials
```

### More examples (`src/examples`)

See `src/examples/` (`usage-scan-socket-ci.yml`, `usage-scan-ci-plus-firewall.yml`, `usage-scan-firewall-free.yml`, `usage-scan-firewall-enterprise.yml`) for additional snippets.

## Behavior

- `socket ci` is equivalent to a full scan with reporting; it exits **0** when the project is healthy under your policies, and **non-zero** when policies fail or the CLI errors. See [socket ci](https://docs.socket.dev/docs/socket-ci) for details.
- The Socket CLI is invoked with `npx --yes socket@<cli_version>`, so the job does not require a global `socket` install.
- **Firewall Free** (`sfw_edition: free`): `npx --yes sfw@<sfw_version> <sfw_command>`. See [Socket Firewall Free](https://docs.socket.dev/docs/socket-firewall-free).
- **Firewall Enterprise** (`sfw_edition: enterprise`): downloads `sfw-linux-x86_64` or `sfw-linux-arm64` from [firewall-release](https://github.com/SocketDev/firewall-release) (musl variants optional), then runs `<sfw_command>` with Enterprise [environment variables](https://docs.socket.dev/docs/socket-firewall-enterprise-configuration) as configured.

## Develop and validate

Sources live under `src/` in the [registry orb layout](https://circleci.com/docs/orbs/author/create-test-and-publish-a-registry-orb/).

```bash
circleci orb pack src > orb.yml
circleci orb validate orb.yml
```

## Release process

Releases are published to the [CircleCI orb registry](https://circleci.com/developer/orbs) as **`gathertown/socket`** by CI when you push a matching **git tag** (see [`.circleci/test-deploy.yml`](.circleci/test-deploy.yml)).

1. **Changelog** — Add a section for the new version in [CHANGELOG.md](CHANGELOG.md) ([Keep a Changelog](https://keepachangelog.com/) style) and merge it to your default branch.

2. **Tag** — Create an annotated or lightweight tag whose name is **SemVer with a `v` prefix**: `vMAJOR.MINOR.PATCH` (for example `v0.0.1` or `v1.2.0`). Tags like `v1.0.0-beta` do **not** match the current pipeline filters.

3. **Push the tag** — `git push origin vX.Y.Z`. That triggers the continuation workflow; **`command-test`** and **`orb-tools/pack`** run, then **`orb-tools/publish`** publishes the orb version that matches the tag (without the leading `v`).

4. **CircleCI setup** — The publish job uses **`context: orb-publishing`**. In your CircleCI organization, that Context must expose a **`CIRCLE_TOKEN`** ([personal API token](https://circleci.com/docs/managing-api-tokens/)) for a user allowed to publish **`gathertown/socket`**. The project must use [dynamic configuration / setup workflows](https://circleci.com/docs/pipelines/#dynamic-configuration) so `orb-tools/continue` can run [`.circleci/test-deploy.yml`](.circleci/test-deploy.yml).

5. **GitHub (optional)** — Create a [GitHub Release](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) for the same tag and paste the notes from **CHANGELOG.md**.

## Troubleshooting

| Issue | What to check |
| ----- | ------------- |
| Authentication errors | `SOCKET_CLI_API_TOKEN` is present on the job (Context or project env), not expired, and has the [required API scopes](https://docs.socket.dev/docs/create-socket-api-key-for-cicd). |
| Wrong organization | Set `org_slug` or `SOCKET_CLI_ORG_SLUG`. |
| Scan runs in the wrong folder | Set `app_dir` to the package or service root (monorepos). |
| Need generated manifests (Gradle, SBT, etc.) | Try `auto_manifest: true` if your stack is supported; ensure any required tooling is available in the image or add install steps before `socket/ci`. |
| `sfw` step fails or wrong package manager | Set `sfw_command` to match your project (for example `npm ci` or `pnpm install --frozen-lockfile`). |
| Enterprise: missing API key | Set `SOCKET_API_KEY` on the job (Context) or add `.sfw.config`; key needs `packages` and `entitlements:list`. |
| Enterprise: wrong architecture | The job selects `x86_64` or `aarch64` Linux binaries from [firewall-release](https://github.com/SocketDev/firewall-release); use `sfw_enterprise_musl` on musl-based images. |
| Uncertified orbs blocked | Org admins may need to allow third-party or community orbs under **Organization Settings → Security**. |

## References

- [CHANGELOG.md](CHANGELOG.md) — version history
- [CircleCI — Orbs overview](https://circleci.com/docs/orbs/use/orb-intro/)
- [Socket — Create API key for CI/CD](https://docs.socket.dev/docs/create-socket-api-key-for-cicd)
- [Socket — `socket ci`](https://docs.socket.dev/docs/socket-ci)
- [Socket — CLI guide](https://docs.socket.dev/docs/socket-cli)
- [Socket — Socket Firewall Free](https://docs.socket.dev/docs/socket-firewall-free)
- [Socket — Socket Firewall Enterprise](https://docs.socket.dev/docs/socket-firewall-enterprise)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
