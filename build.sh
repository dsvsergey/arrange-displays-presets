#!/bin/bash
# Builds "Display Presets.app" into ./build. Pass --install to copy it to /Applications.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
APP="build/Display Presets.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/DisplayPresets" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built: $APP"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x DisplayPresets 2>/dev/null || true
    rm -rf "/Applications/Display Presets.app"
    cp -R "$APP" /Applications/
    open "/Applications/Display Presets.app"
    echo "Installed to /Applications"
fi
