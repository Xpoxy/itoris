#!/usr/bin/env bash
set -uo pipefail

if ! command -v "jq" &> /dev/null; then
	echo "jq is required to read project configuration."
	exit 1
fi

GLOBAL_CONFIG_DIR="$HOME/.config/itoris"
mkdir -p "$GLOBAL_CONFIG_DIR"
LAST_PROJECT_FILE="$GLOBAL_CONFIG_DIR/last-project"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export ITORIS_SCRIPTS_DIR="$SCRIPT_DIR/scripts"

if [[ -v 1 ]]; then
	export PROJECT_ROOT=$(realpath "$1")
	echo "$PROJECT_ROOT" > "$LAST_PROJECT_FILE"
else
	if [[ -f "$LAST_PROJECT_FILE" ]]; then
		export PROJECT_ROOT=$(cat "$LAST_PROJECT_FILE")
	else
		echo "Usage: $0 <project-root>" >&2
		kill $EDITOR_PID
		exit 1
	fi
fi

if [[ ! -d $PROJECT_ROOT ]]; then
	echo "No project directory: $PROJECT_ROOT"
	kill $EDITOR_PID
	exit 1
fi

echo "Setting project root: $PROJECT_ROOT"

cd $PROJECT_ROOT

if [[ ! -v EDITOR_PID ]]; then
	$EDITOR $PROJECT_ROOT > /dev/null 2>&1 &
	export EDITOR_PID=$!
fi

export CONFIG_FILE="$PROJECT_ROOT/.toris.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
	echo "Project has no configuration, creating an empty one at $CONFIG_FILE"
	echo "{" > $CONFIG_FILE
	echo "    \"profiles\": []" >> $CONFIG_FILE
	echo "}" >> $CONFIG_FILE
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ITORIS_SESSION=$$
export ITORIS_BIN="$(realpath $0)"

SOFT_PROCS=()

trap 'echo "Killing all watchers..."; for pid in ${SOFT_PROCS[@]:-}; do kill -9 -- "-$pid" 2>/dev/null; done; exit' INT TERM EXIT

while read -r PROFILE; do
    BUNDLE=$(echo "$PROFILE" | jq -r ".bundle")
    BUNDLE_PATH="$PROJECT_ROOT/$BUNDLE"

    # if there isn't a project local bundle select a global:
    if [[ ! -d "$BUNDLE_PATH" ]]; then
        BUNDLE_PATH="$SCRIPT_DIR/bundles/$BUNDLE"
    fi
    # if there is no bundle:
    if [[ ! -d "$BUNDLE_PATH" ]]; then
        echo "[$ITORIS_SESSION] Bad bundle: $BUNDLE, skipping profile"
        continue
    fi

    echo "[$ITORIS_SESSION] Selected bundle: $BUNDLE_PATH"

    RECURSIVE=$(echo "$PROFILE" | jq -r ".recursive")
    if [ "$RECURSIVE" == "false" ]; then
        RECURSIVE=""
    else
        RECURSIVE="-r"
    fi

    TARGETS=$(echo "$PROFILE" | jq -c ".targets")

    while read -r TARGET; do
        FILES_AND_DIRS=($PROJECT_ROOT/$TARGET)
        for FD in "${FILES_AND_DIRS[@]}"; do
            if [[ ! -d "$FD" ]]; then
                continue
            fi
            echo "[$ITORIS_SESSION] Setting up inotify hook on: $FD"
            setsid "$SCRIPT_DIR/setup-inotify-hooks.sh" "$FD" "$BUNDLE_PATH" "$RECURSIVE" &
            SOFT_PROCS+=("$!")
        done
    done < <(echo "$TARGETS" | jq -r ".[]")

done < <(jq -c ".profiles[]" "$CONFIG_FILE")

while true; do
	sleep 30
	if ! ps -p $EDITOR_PID > /dev/null; then
		exit 0
	fi
done
