#!/usr/bin/env bash
set -uo pipefail

if [[ -d "$2" ]]; then
	"$ITORIS_SCRIPTS_DIR/reload-session.sh"
fi
