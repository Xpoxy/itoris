#!/usr/bin/env bash
set -uo pipefail

if [[ ! -v ITORIS_SESSION ]]; then
	echo "This script can only be run in an itoris session"
	exit 1
fi

kill "$ITORIS_SESSION"
sleep 0.2

export EDITOR_PID
exec "$ITORIS_BIN"
