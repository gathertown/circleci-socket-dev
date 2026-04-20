set -euo pipefail
EDITION="<< parameters.sfw_edition >>"
if [ "$EDITION" = "enterprise" ]; then
  if [ -z "${SOCKET_API_KEY:-}" ] && [ ! -f .sfw.config ]; then
    echo "Socket Firewall Enterprise requires SOCKET_API_KEY in the job environment (recommended: Context) or a .sfw.config file in the app directory." >&2
    echo "See https://docs.socket.dev/docs/socket-firewall-enterprise-wrapper-mode" >&2
    exit 1
  fi
  if [ "<< parameters.sfw_config_relative_paths >>" = "true" ]; then
    export SFW_CONFIG_RELATIVE_PATHS=true
  fi
  if [ -n "<< parameters.sfw_custom_registries >>" ]; then
    export SFW_CUSTOM_REGISTRIES='<< parameters.sfw_custom_registries >>'
  fi
  if [ -n "<< parameters.sfw_unknown_host_action >>" ]; then
    export SFW_UNKNOWN_HOST_ACTION='<< parameters.sfw_unknown_host_action >>'
  fi
  if [ "<< parameters.sfw_telemetry_disabled >>" = "true" ]; then
    export SFW_TELEMETRY_DISABLED=true
  fi
  if [ "<< parameters.sfw_debug >>" = "true" ]; then
    export SFW_DEBUG=true
  fi
  ARCH=$(uname -m)
  MUSL="<< parameters.sfw_enterprise_musl >>"
  if [ "$MUSL" = "true" ]; then
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
  ENT_VER="<< parameters.sfw_enterprise_version >>"
  if [ -z "$ENT_VER" ] || [ "$ENT_VER" = "latest" ]; then
    URL="https://github.com/SocketDev/firewall-release/releases/latest/download/${BIN}"
  else
    URL="https://github.com/SocketDev/firewall-release/releases/download/v${ENT_VER}/${BIN}"
  fi
  echo "Downloading Socket Firewall Enterprise: ${URL}"
  curl -fsSL -o /tmp/sfw-enterprise "$URL"
  chmod +x /tmp/sfw-enterprise
  /tmp/sfw-enterprise << parameters.sfw_command >>
else
  npx --yes sfw@<< parameters.sfw_version >> << parameters.sfw_command >>
fi
