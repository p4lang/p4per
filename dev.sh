#!/usr/bin/env bash
# Run commands inside the dev container.
set -euo pipefail

WORKSPACE_FOLDER="$(cd "$(dirname "$0")" && pwd)"

devcontainer up --workspace-folder "$WORKSPACE_FOLDER" >/dev/null
devcontainer exec --workspace-folder "$WORKSPACE_FOLDER" "$@"
