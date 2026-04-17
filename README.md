# CircleCI Socket.dev orb

Reusable CircleCI configuration for running [Socket.dev](https://socket.dev) policy checks in your pipelines. The orb invokes the official Socket CLI with [`socket ci`](https://docs.socket.dev/docs/socket-ci), which creates a scan, waits for results, and fails the build when your security or license policies are violated.

## Requirements

- CircleCI configuration **version 2.1**
- A [Socket.dev](https://socket.dev) organization and a CI API token with the scopes described in [Create Socket API Key for CI/CD](https://docs.socket.dev/docs/create-socket-api-key-for-cicd)
- The [CircleCI CLI](https://circleci.com/docs/guides/local-cli/) if you pack or validate the orb locally (`circleci orb pack`, `circleci orb validate`)

## Authentication

Jobs must have **`SOCKET_CLI_API_TOKEN`** set in the environment. Typical approaches:

| Approach | Notes |
| -------- | ----- |
| **Project settings** | Environment Variables → add `SOCKET_CLI_API_TOKEN` (mark sensitive). |
| **Context** | Define the variable on a Context and attach `context: <name>` to the job. Preferred for sharing secrets across projects. |

Optional:

- **`SOCKET_CLI_ORG_SLUG`** — Use when your token applies to more than one Socket organization, or you need to pin a specific org. You can also set this with the orb parameter `org_slug` on the `ci` command or `scan` job.

Other variables (for example `SOCKET_CLI_GITHUB_TOKEN` / `GITHUB_TOKEN` if the CLI must reach GitHub) follow the [Socket CLI](https://docs.socket.dev/docs/socket-cli) behavior; set them as project or Context variables as needed.

## Installation

After you [pack and publish](#develop-pack-and-publish) this orb under your CircleCI namespace (for example `gathertown/socket@1.0.0`), declare it in `.circleci/config.yml`:

```yaml
version: 2.1

orbs:
  socket: gathertown/socket@1.0.0
```

To consume the orb from a raw URL instead of the registry, add your URL prefix to the [organization URL orb allow list](https://circleci.com/docs/orbs/use/managing-url-orbs-allow-lists/) and reference the packed YAML file as in the [URL orbs](https://circleci.com/docs/orbs/use/orb-intro/) documentation.

## Usage

### Job: `scan`

Runs `checkout` and then `socket ci` via the `ci` command. Use this when you want a single job with sensible defaults.

```yaml
workflows:
  security:
    jobs:
      - socket/scan:
          context: socket-credentials
```

Minimal configuration: a Context (or project env) that defines `SOCKET_CLI_API_TOKEN`.

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

### Executor: `default`

`cimg/node` with a configurable image tag. Use when you author jobs that call `socket/ci` manually.

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

### `jobs/scan`

Inherits the same scanning behavior as `commands/ci` via forwarded parameters, plus:

| Parameter | Type | Default | Description |
| --------- | ---- | ------- | ----------- |
| `node_tag` | string | `current` | [cimg/node](https://hub.docker.com/r/cimg/node/tags) tag for the Docker executor. |
| `resource_class` | string | `medium` | [CircleCI resource class](https://circleci.com/docs/configuration-reference/#resourceclass) for the job (for example `medium`, `large`, `arm.medium`). |

Forwarded to `ci`: `cli_version`, `auto_manifest`, `app_dir`, `org_slug`, `extra_args`.

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

### Registry usage example

See `src/examples/basic.yml` for an orb-registry-style snippet you can adapt when publishing.

## Behavior

- `socket ci` is equivalent to a full scan with reporting; it exits **0** when the project is healthy under your policies, and **non-zero** when policies fail or the CLI errors. See [socket ci](https://docs.socket.dev/docs/socket-ci) for details.
- The CLI is invoked with `npx --yes socket@<cli_version>`, so the job does not require a global `socket` install.

## Develop, pack, and publish

Sources live under `src/` in the [registry orb layout](https://circleci.com/docs/orbs/author/create-test-and-publish-a-registry-orb/).

```bash
circleci orb pack src > orb.yml
circleci orb validate orb.yml
```

Publish `orb.yml` to the `gathertown` namespace with the CircleCI CLI or your release process. Update `display.source_url` in `src/@orb.yml` if the canonical Git repository URL changes.

## Troubleshooting

| Issue | What to check |
| ----- | ------------- |
| Authentication errors | `SOCKET_CLI_API_TOKEN` is present on the job (Context or project env), not expired, and has the [required API scopes](https://docs.socket.dev/docs/create-socket-api-key-for-cicd). |
| Wrong organization | Set `org_slug` or `SOCKET_CLI_ORG_SLUG`. |
| Scan runs in the wrong folder | Set `app_dir` to the package or service root (monorepos). |
| Need generated manifests (Gradle, SBT, etc.) | Try `auto_manifest: true` if your stack is supported; ensure any required tooling is available in the image or add install steps before `socket/ci`. |
| Uncertified orbs blocked | Org admins may need to allow third-party or community orbs under **Organization Settings → Security**. |

## References

- [CircleCI — Orbs overview](https://circleci.com/docs/orbs/use/orb-intro/)
- [Socket — Create API key for CI/CD](https://docs.socket.dev/docs/create-socket-api-key-for-cicd)
- [Socket — `socket ci`](https://docs.socket.dev/docs/socket-ci)
- [Socket — CLI guide](https://docs.socket.dev/docs/socket-cli)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
