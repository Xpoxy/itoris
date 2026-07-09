#!/usr/bin/env bash
set -uo pipefail

if [[ -d "$2" ]]; then
	mkdir -p "$2/src"
	mkdir -p "$2/resources"
	echo "# $(basename $2)" > "$2/README.md"
fi
