set -euo pipefail
# Orb parameters are passed via the run step `environment` block only — no
# `<< parameters.* >>` in this file (bash would treat `<<` as a heredoc when
# CircleCI substitution does not run as expected inside <<include()>>).

# CircleCI may pass boolean orb parameters into `environment` as "true"/"false" or
# "1"/"0" (see reusable config docs). Match all common truthy/falsy forms.
orb_bool_true() {
  case "${1:-}" in
    true|True|TRUE|1|yes|Yes|YES|on|On|ON) return 0 ;;
    *) return 1 ;;
  esac
}

EDITION="${ORB_SFW_EDITION:-free}"
if [ "$EDITION" = "enterprise" ]; then
  if [ -z "${SOCKET_API_KEY:-}" ] && [ ! -f .sfw.config ]; then
    echo "Socket Firewall Enterprise requires SOCKET_API_KEY in the job environment (recommended: Context) or a .sfw.config file in the app directory." >&2
    echo "See https://docs.socket.dev/docs/socket-firewall-enterprise-wrapper-mode" >&2
    exit 1
  fi
  if orb_bool_true "${ORB_SFW_CONFIG_RELATIVE_PATHS:-false}"; then
    export SFW_CONFIG_RELATIVE_PATHS=true
  fi
  if [ -n "${ORB_SFW_CUSTOM_REGISTRIES:-}" ]; then
    export SFW_CUSTOM_REGISTRIES="${ORB_SFW_CUSTOM_REGISTRIES}"
  fi
  if [ -n "${ORB_SFW_UNKNOWN_HOST_ACTION:-}" ]; then
    export SFW_UNKNOWN_HOST_ACTION="${ORB_SFW_UNKNOWN_HOST_ACTION}"
  fi
  if orb_bool_true "${ORB_SFW_TELEMETRY_DISABLED:-false}"; then
    export SFW_TELEMETRY_DISABLED=true
  fi
  if orb_bool_true "${ORB_SFW_DEBUG:-false}"; then
    export SFW_DEBUG=true
  fi
  ARCH=$(uname -m)
  MUSL="${ORB_SFW_ENTERPRISE_MUSL:-false}"
  if orb_bool_true "$MUSL"; then
    case "$ARCH" in
      x86_64) BIN=sfw-musl-linux-x86_64 ;;
      aarch64) BIN=sfw-musl-linux-arm64 ;;
      *)
        echo "Unsupported CPU architecture for musl Socket Firewall binary: $ARCH" >&2
        exit 1
        ;;
    esac
  else
    case "$ARCH" in
      x86_64) BIN=sfw-linux-x86_64 ;;
      aarch64) BIN=sfw-linux-arm64 ;;
      *)
        echo "Unsupported CPU architecture for Socket Firewall Enterprise Linux binary: $ARCH" >&2
        exit 1
        ;;
    esac
  fi
  ENT_VER="${ORB_SFW_ENTERPRISE_VERSION:-latest}"
  if [ -z "$ENT_VER" ] || [ "$ENT_VER" = "latest" ]; then
    URL="https://github.com/SocketDev/firewall-release/releases/latest/download/${BIN}"
  else
    URL="https://github.com/SocketDev/firewall-release/releases/download/v${ENT_VER}/${BIN}"
  fi
  echo "Downloading Socket Firewall Enterprise: ${URL}"
  curl -fsSL -o /tmp/sfw-enterprise "$URL"
  chmod +x /tmp/sfw-enterprise
  # shellcheck disable=SC2086
  /tmp/sfw-enterprise ${ORB_SFW_COMMAND:?ORB_SFW_COMMAND must be set by the orb (sfw_command parameter)}
else
  SFW_VER="${ORB_SFW_VERSION:-latest}"
  # shellcheck disable=SC2086
  npx --yes sfw@${SFW_VER} ${ORB_SFW_COMMAND:?ORB_SFW_COMMAND must be set by the orb (sfw_command parameter)}
fi
