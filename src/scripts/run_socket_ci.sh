set -euo pipefail
if [ -n "<< parameters.org_slug >>" ]; then
  export SOCKET_CLI_ORG_SLUG="<< parameters.org_slug >>"
fi
npx --yes socket@<< parameters.cli_version >> ci<<# parameters.auto_manifest>> --autoManifest<</ parameters.auto_manifest>> << parameters.extra_args >>
