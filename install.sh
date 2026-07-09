#!/usr/bin/env bash
set -uo pipefail

DEPS_STATUS=0

if ! command -v "bash" &> /dev/null; then
	echo "bash is required to run itoris."
	DEPS_STATUS=1
fi

if ! command -v "readlink" &> /dev/null; then
	echo "readlink is required to run itoris."
	DEPS_STATUS=1
fi

if ! command -v "jq" &> /dev/null; then
	echo "jq is required to read project configuration."
	DEPS_STATUS=1
fi

if ! command -v "inotifywait" &> /dev/null; then
	echo "libinotify-tools is required to run itoris."
	DEPS_STATUS=1
fi

if ! command -v "python3" &> /dev/null; then
	echo "Warning: Some important optional dependencies are missing:"
	echo "python3 is needed to run some pre-packaged scripts."
fi

if [[ "$DEPS_STATUS" == 1 ]]; then
	echo "Failed to install! Some dependencies are missing."
	exit 1
fi

SCRIPT_DIR="$(realpath "$(dirname "$(readlink -f $0)")")"

path_contains() {
	local dir="$1"
	[[ ":$PATH:" == *":$dir:"* ]]
}

if pgrep -s 0 '^sudo$' > /dev/null ; then
	echo 'Running install as sudo, installing globally...'
	INSTALL_DIR="/opt"
	sudo mkdir -p "$INSTALL_DIR"
	sudo cp -r "$SCRIPT_DIR" "$INSTALL_DIR/"
	sudo rm -f "$INSTALL_DIR/itoris/install.sh"
	sudo chmod -R 755 "$INSTALL_DIR/itoris"
	BIN_DIR="/usr/local/bin"
	sudo ln -sf "$INSTALL_DIR/itoris/itoris" "$BIN_DIR/itoris"
else
	echo 'Running install as user, installing locally...'
	INSTALL_DIR="$HOME/.local"
	mkdir -p "$INSTALL_DIR"
	cp -r "$SCRIPT_DIR" "$INSTALL_DIR/"
	rm -f "$INSTALL_DIR/itoris/install.sh"
	BIN_DIR="$HOME/.local/bin"
	mkdir -p "$BIN_DIR"
	ln -sf "$INSTALL_DIR/itoris/itoris" "$HOME/.local/bin/itoris"
fi

echo "Installation complete!"
echo

if ! path_contains "$BIN_DIR"; then
	echo "Warning: $BIN_DIR is not in PATH"
	echo "To run itoris please add it to your PATH!"
	echo
	echo "Add this to your ~/.bashrc or ~/.zshrc:"
	echo "export PATH=\"$BIN_DIR:\$PATH\""
else
	echo "Run itoris <project_path> to get itoris started on a project directory."
	echo "Itoris remembers your last project directory, so you may run itoris"
	echo "without any parameters next time."
	echo
	echo "By default, itoris will create an empty config file (.toris.json) in your"
	echo "project root, add profiles or copy one from $INSTALL_DIR/itoris/project-templates"
	echo "to run scripts when inotify events happen."
fi
