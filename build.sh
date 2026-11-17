#!/bin/bash
# Builds all three apps, moves them to /Applications and adds Desktop shortcuts.
# Usage: ./build.sh            (all three)
#        ./build.sh weekly     (just one: weekly | monthly | yearly)
set -e
cd "$(dirname "$0")"

# Turns a 1024px PNG into an .icns using macOS built-in sips + iconutil
make_icns() {
  local PNG="$1" OUT="$2"
  [ -f "$PNG" ] || { echo "(no icon at $PNG, skipping)"; return 0; }
  local SET; SET="$(mktemp -d)/AppIcon.iconset"; mkdir -p "$SET"
  for s in 16 32 128 256 512; do
    sips -z $s $s "$PNG" --out "$SET/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$PNG" --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$SET" -o "$OUT"
}

build_one() {
  local TARGET="$1" NAME="$2" ID="$3"
  local APP="build/$NAME.app"
  echo "▶ $NAME"
  swift build -c release --product "$TARGET"
  local BIN; BIN="$(swift build -c release --show-bin-path)/$TARGET"

  rm -rf "$APP"
  mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
  cp "$BIN" "$APP/Contents/MacOS/$TARGET"
  cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleIdentifier</key><string>$ID</string>
  <key>CFBundleExecutable</key><string>$TARGET</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
  make_icns "Icons/$TARGET.png" "$APP/Contents/Resources/AppIcon.icns"
  codesign --force --deep --sign - "$APP"   # ad-hoc sign so notifications work

  rm -rf "/Applications/$NAME.app"
  cp -R "$APP" "/Applications/$NAME.app" 2>/dev/null || sudo cp -R "$APP" "/Applications/$NAME.app"

  rm -f "$HOME/Desktop/$NAME" "$HOME/Desktop/$NAME.app"
  osascript -e "tell application \"Finder\" to make alias file to POSIX file \"/Applications/$NAME.app\" at POSIX file \"$HOME/Desktop\"" >/dev/null 2>&1 \
    || ln -s "/Applications/$NAME.app" "$HOME/Desktop/$NAME"
}

WHICH="all"
for a in "$@"; do case "$a" in weekly|monthly|yearly) WHICH="$a";; esac; done
[[ "$WHICH" == "all" || "$WHICH" == "weekly"  ]] && build_one WeeklyRituals  "Weekly Rituals"  com.family.WeeklyRituals
[[ "$WHICH" == "all" || "$WHICH" == "monthly" ]] && build_one MonthlyRituals "Monthly Rituals" com.family.MonthlyRituals
[[ "$WHICH" == "all" || "$WHICH" == "yearly"  ]] && build_one YearlyRituals  "Yearly Rituals"  com.family.YearlyRituals

echo "✅ Installed in /Applications with Desktop shortcuts."
if [[ "$WHICH" == "all" ]]; then open "/Applications/Weekly Rituals.app" "/Applications/Monthly Rituals.app" "/Applications/Yearly Rituals.app"; fi

# Optional: ./build.sh --github also creates the GitHub repo (needs gh installed and logged in)
if [[ " $* " == *" --github "* ]]; then ./publish.sh; fi
