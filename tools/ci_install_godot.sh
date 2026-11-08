#!/usr/bin/env bash
# CI helper: download Godot $GODOT_VERSION-$GODOT_STATUS (Linux editor) to ~/godot/godot
# and unpack only the export templates the given platforms need.
#
# Usage: tools/ci_install_godot.sh web [windows linux macos]
# Needs GODOT_VERSION, GODOT_STATUS and GH_TOKEN in the environment.
set -euo pipefail

TAG="${GODOT_VERSION}-${GODOT_STATUS}"
T=~/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_STATUS}

files=(templates/version.txt)
for p in "$@"; do
  case "$p" in
    web)     files+=(templates/web_nothreads_release.zip) ;;
    windows) files+=(templates/windows_release_x86_64.exe) ;;
    linux)   files+=(templates/linux_release.x86_64) ;;
    macos)   files+=(templates/macos.zip) ;;
    *) echo "Unknown platform: $p" >&2; exit 1 ;;
  esac
done

mkdir -p ~/godot /tmp/godot-dl "$T"
cd /tmp/godot-dl
gh release download "$TAG" -R godotengine/godot \
  -p "Godot_v${TAG}_linux.x86_64.zip" \
  -p "Godot_v${TAG}_export_templates.tpz"
unzip -q -o "Godot_v${TAG}_linux.x86_64.zip" -d ~/godot
mv ~/godot/Godot_v${TAG}_linux.x86_64 ~/godot/godot
chmod +x ~/godot/godot
# The full template set is ~1.3 GB; keep only what the presets need.
unzip -q -o -j "Godot_v${TAG}_export_templates.tpz" "${files[@]}" -d "$T"
rm -rf /tmp/godot-dl
ls -la "$T"
