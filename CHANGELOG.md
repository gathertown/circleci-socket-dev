# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-04-20

### Added

- Orb `gathertown/socket` for running [Socket.dev](https://socket.dev) in CircleCI.
- **Job `scan`**: checkout plus configurable **`mode`**: `ci` (Socket CLI policy scan only), `sfw` (Socket Firewall only), or `both` (firewall step then `socket ci`).
- **Command `ci`**: runs `npx socket@… ci` with parameters for `cli_version`, `auto_manifest`, `app_dir`, `org_slug`, and `extra_args`. Expects `SOCKET_CLI_API_TOKEN` when used.
- **Command `sfw`**: runs Socket Firewall with **`sfw_edition`** `free` (`npx sfw`) or `enterprise` (official binary from [firewall-release](https://github.com/SocketDev/firewall-release)); optional Enterprise settings via parameters and `SOCKET_API_KEY` or `.sfw.config` for Enterprise.
- **Executor `default`**: `cimg/node` with configurable tag.
- Usage examples under `src/examples/` (`usage-scan-*.yml`).
- Shell scripts included via `<<include()>>` for `ci` and `sfw` commands.
