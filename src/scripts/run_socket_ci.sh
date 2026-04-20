set -euo pipefail
# Parameters are passed via `environment` on the run step so this file never contains raw
# `<<` from CircleCI (bash would interpret it as a heredoc when used with <<include()>>).
if [ -n "${SOCKET_CI_ORG_SLUG:-}" ]; then
  export SOCKET_CLI_ORG_SLUG="$SOCKET_CI_ORG_SLUG"
fi
CLI_VER="${SOCKET_CI_CLI_VERSION:-latest}"
AUTO_FLAGS=()
case "${SOCKET_CI_AUTO_MANIFEST:-false}" in
  true | 1 | yes) AUTO_FLAGS+=(--autoManifest) ;;
esac
# shellcheck disable=SC2086
exec npx --yes socket@${CLI_VER} ci "${AUTO_FLAGS[@]}" ${SOCKET_CI_EXTRA_ARGS:-}
