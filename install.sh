#!/usr/bin/env bash
# Install gitlogue and copy the OS-specific wrappers into INSTALL_DIR.
# Usage: ./install.sh
set -euo pipefail

# macOS ships an ancient bash. Use a modern bash if available, caching the
# path so we don't search Homebrew on every run. This block is bash 3 compatible.
_bash_major() {
	if [ -n "${BASH_VERSION:-}" ]; then
		printf '%s' "$BASH_VERSION" | cut -d. -f1
	else
		printf '0'
	fi
}

if [ "$(_bash_major)" -lt 4 ]; then
	CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/gitlogue"
	BASH_CACHE="$CACHE_DIR/bash"
	BASH_PATH=""

	if [ -r "$BASH_CACHE" ]; then
		read -r BASH_PATH < "$BASH_CACHE" || true
	fi

	if [ -n "${BASH_PATH:-}" ] && [ -x "$BASH_PATH" ] && "$BASH_PATH" --version >/dev/null 2>&1; then
		exec "$BASH_PATH" "$0" "$@"
	fi

	for candidate in /opt/homebrew/bin/bash /usr/local/bin/bash; do
		if [ -x "$candidate" ] && "$candidate" --version >/dev/null 2>&1; then
			BASH_PATH="$candidate"
			break
		fi
	done

	if [ -z "${BASH_PATH:-}" ]; then
		echo "gitlogue-wrappers install requires bash 4+. Please install bash via Homebrew:" >&2
		echo "  brew install bash" >&2
		exit 1
	fi

	mkdir -p "$CACHE_DIR"
	printf '%s\n' "$BASH_PATH" > "$BASH_CACHE"
	exec "$BASH_PATH" "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

install_gitlogue() {
	curl -fsSL https://raw.githubusercontent.com/unhappychoice/gitlogue/main/scripts/install.sh | bash
}

install_watcher() {
	case "${1,,}" in
		darwin*)
			if ! command -v fswatch >/dev/null 2>&1; then
				echo "Installing fswatch..."
				brew install fswatch
			fi
			;;
		linux*|*)
			if ! command -v inotifywait >/dev/null 2>&1; then
				echo "Installing inotify-tools..."
				if command -v apt-get >/dev/null 2>&1; then
					sudo apt-get install -y inotify-tools
				elif command -v dnf >/dev/null 2>&1; then
					sudo dnf install -y inotify-tools
				elif command -v pacman >/dev/null 2>&1; then
					sudo pacman -S --needed --noconfirm inotify-tools
				elif command -v zypper >/dev/null 2>&1; then
					sudo zypper install -y inotify-tools
				elif command -v apk >/dev/null 2>&1; then
					sudo apk add inotify-tools
				else
					echo "Could not detect package manager. Please install inotify-tools manually." >&2
					exit 1
				fi
			fi
			;;
	esac
}

install_wrappers() {
	local os suffix
	os="$(uname -s)"
	case "${os,,}" in
		darwin*) suffix="macos" ;;
		*)       suffix="linux" ;;
	esac

	mkdir -p "$INSTALL_DIR"
	cp "$SCRIPT_DIR/gitlogue-commits-watch-$suffix" "$INSTALL_DIR/gitlogue-commits-watch"
	cp "$SCRIPT_DIR/gitlogue-unstaged-watch-$suffix" "$INSTALL_DIR/gitlogue-unstaged-watch"
	chmod +x "$INSTALL_DIR/gitlogue-commits-watch" "$INSTALL_DIR/gitlogue-unstaged-watch"
	echo "Installed wrappers to $INSTALL_DIR"
}

main() {
	local os
	os="$(uname -s)"

	install_gitlogue
	install_watcher "$os"
	install_wrappers

	echo "Done. Make sure $INSTALL_DIR is on your PATH."
}

main "$@"
