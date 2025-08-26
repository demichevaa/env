#!/usr/bin/env bash
set -euo pipefail

# Config
SRC_DEFAULT="/opt/daa/env/firefox/userChrome.css"   # <-- your repo path
SRC="${SRC:-$SRC_DEFAULT}"
PROFILE_BASE="${PROFILE_BASE:-$HOME/.mozilla/firefox}"

# Collect profiles from profiles.ini
mapfile -t PROFILES < <(grep '^Path=' "$PROFILE_BASE/profiles.ini" | cut -d= -f2)

if [ ${#PROFILES[@]} -eq 0 ]; then
  echo "No profiles found in $PROFILE_BASE/profiles.ini"; exit 1
fi

# No arg => list with full paths
if [ $# -ne 1 ]; then
  echo "Available profiles:"
  for i in "${!PROFILES[@]}"; do
    echo "  [$i] $PROFILE_BASE/${PROFILES[$i]}"
  done
  echo; echo "Usage: $0 <profile-number>"; exit 1
fi

# Pick profile by numeric index
IDX="$1"
[[ "$IDX" =~ ^[0-9]+$ ]] || { echo "Argument must be a number"; exit 1; }
(( IDX < ${#PROFILES[@]} )) || { echo "Invalid index. Range: 0..$(( ${#PROFILES[@]} - 1 ))"; exit 1; }

PROFILE_DIR="$PROFILE_BASE/${PROFILES[$IDX]}"
CHROME_DIR="$PROFILE_DIR/chrome"
SYMLINK="$CHROME_DIR/userChrome.css"
USERJS="$PROFILE_DIR/user.js"

# Sanity
[ -f "$SRC" ] || { echo "ERROR: CSS not found: $SRC"; exit 2; }

# Deploy
mkdir -p "$CHROME_DIR"
ln -sfn "$SRC" "$SYMLINK"

# Ensure legacy userChrome is enabled (append, don't overwrite)
PREF='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
if [ -f "$USERJS" ]; then
  grep -q 'toolkit\.legacyUserProfileCustomizations\.stylesheets' "$USERJS" || echo "$PREF" >> "$USERJS"
else
  printf '// auto-generated\n%s\n' "$PREF" > "$USERJS"
fi

# Show exactly what happened
echo "Symlink created:"
ls -la "$SYMLINK" || true
echo "Resolved target: $(readlink -f "$SYMLINK" || echo 'unresolvable')"
echo "user.js: $USERJS"
tail -n +1 "$USERJS" | sed 's/^/  /'

echo "Done. Restart Firefox."

