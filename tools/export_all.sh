#!/usr/bin/env bash
# Export the game for every platform in export_presets.cfg.
#
#   Web      -> web/play/        (the website in web/ links to it)
#   Windows  -> build/windows/UniversalBeatdown.exe
#   Linux    -> build/linux/UniversalBeatdown.x86_64
#   macOS    -> build/macos/UniversalBeatdown.zip
#
# Usage: tools/export_all.sh [path-to-godot]   (default: $GODOT, then "godot")
# The matching export templates must be installed (Editor > Manage Export Templates).
set -euo pipefail

GODOT="${1:-${GODOT:-godot}}"
cd "$(dirname "$0")/.."

# The Godot AI (MCP) helper is an editor-only debugging tool, and addons/ is not
# exported. Drop its autoload for the export so the game doesn't log a
# "missing autoload script" error at startup. project.godot is restored afterwards.
cp project.godot project.godot.orig
trap 'mv project.godot.orig project.godot' EXIT
grep -v -e '^_mcp_game_helper=' -e '^enabled=PackedStringArray("res://addons/godot_ai/' \
  project.godot.orig > project.godot

echo "== Importing assets"
"$GODOT" --headless --import

export_one() {
  local preset="$1" out="$2"
  mkdir -p "$(dirname "$out")"
  echo "== Exporting $preset -> $out"
  "$GODOT" --headless --export-release "$preset" "$out"
  if [ ! -s "$out" ]; then
    echo "ERROR: export of '$preset' produced no file at $out" >&2
    exit 1
  fi
}

rm -rf web/play build
export_one "Web"             web/play/index.html
export_one "Windows Desktop" build/windows/UniversalBeatdown.exe
export_one "Linux"           build/linux/UniversalBeatdown.x86_64
export_one "macOS"           build/macos/UniversalBeatdown.zip

echo "== Done"
ls -la web/play build/*
