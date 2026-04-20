# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.2] - 2026-04-21

### Fixed

- **Runtime:** Resolved Bash heredoc / syntax errors when using `socket/sfw` and `socket/ci` with `<<include()>>` shell scripts. Unsubstituted `<< parameters.* >>` inside included files could be parsed by Bash as here-documents (`<<`). All dynamic values for those commands are now passed via the `run` step `environment` block (`ORB_SFW_COMMAND`, `ORB_SFW_*`, `SOCKET_CI_*`); included scripts contain no CircleCI parameter placeholders.
- **Bash / `<<include()>>`:** CircleCI `<< parameters.* >>` placeholders inside included shell scripts were not always substituted before Bash ran the script. Bash then treated `<<` as the start of a **here-document**, causing warnings like `wanted 'parameters.sfw_command'` / `parameters.cli_version` and `syntax error near unexpected token`. This affected **`socket/sfw`** (Free and Enterprise) and **`socket/ci`** on real executors (e.g. `cimg/node`).
- **Mitigation:** Dynamic values are passed only via the `run` step **`environment`** block:
  - **`socket/sfw`:** `ORB_SFW_COMMAND`, `ORB_SFW_EDITION`, `ORB_SFW_VERSION`, `ORB_SFW_ENTERPRISE_*`, and related Enterprise flags (orb-internal `ORB_*` prefix avoids colliding with Socket Firewall’s `SFW_*` env vars). `src/scripts/run_sfw.sh` contains **no** `<< parameters.* >>` tokens.
  - **`socket/ci`:** `SOCKET_CI_CLI_VERSION`, `SOCKET_CI_ORG_SLUG`, `SOCKET_CI_EXTRA_ARGS`, `SOCKET_CI_AUTO_MANIFEST` in `src/scripts/run_socket_ci.sh`.

**Upgrade:** Consumers on `gathertown/socket@0.0.1` should pin **`@0.0.2`** or later.

## [0.0.1] - 2026-04-20

### Added

- Orb `gathertown/socket` for running [Socket.dev](https://socket.dev) in CircleCI.
- **Job `scan`**: checkout plus configurable **`mode`**: `ci` (Socket CLI policy scan only), `sfw` (Socket Firewall only), or `both` (firewall step then `socket ci`).
- **Command `ci`**: runs `npx socket@… ci` with parameters for `cli_version`, `auto_manifest`, `app_dir`, `org_slug`, and `extra_args`. Expects `SOCKET_CLI_API_TOKEN` when used.
- **Command `sfw`**: runs Socket Firewall with **`sfw_edition`** `free` (`npx sfw`) or `enterprise` (official binary from [firewall-release](https://github.com/SocketDev/firewall-release)); optional Enterprise settings via parameters and `SOCKET_API_KEY` or `.sfw.config` for Enterprise.
- **Executor `default`**: `cimg/node` with configurable tag.
- Usage examples under `src/examples/` (`usage-scan-*.yml`).
- Shell scripts included via `<<include()>>` for `ci` and `sfw` commands.
