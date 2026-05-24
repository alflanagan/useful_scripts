#!/usr/bin/env zsh
# uninstall_app.sh — fully remove a macOS application and its leftover data

set -euo pipefail
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

usage() {
  echo "Usage: $(basename "$0") <AppName>"
  echo "  AppName: the name of the app as it appears in /Applications."
  echo "  This version works for apps that do *not* have .app appended to their bundle name."
  echo "Example: $(basename "$0") \"Spotify.app\""
  exit 1
}

[[ $# -lt 1 ]] && usage

APP_NAME="$1"
APP_BUNDLE="${APP_NAME}"
REMOVED=()
NOT_FOUND=()

# Derive bundle identifier from the app if it exists
get_bundle_id() {
  local app_path="$1"
  /usr/bin/defaults read "${app_path}/Contents/Info" CFBundleIdentifier 2>/dev/null || true
}

confirm() {
  local prompt="$1"
  echo -n "${prompt} [y/N] "
  read -r reply
  [[ "${reply:l}" == "y" ]]
}

remove_path() {
  local target_path="$1"
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    if confirm "  Remove: ${target_path}?"; then
      rm -rf "$target_path"
      REMOVED+=("$target_path")
    fi
  fi
}

# ── Locate app ────────────────────────────────────────────────────────────────
APP_PATH=""
for dir in "/Applications" "${HOME}/Applications"; do
  if [[ -d "${dir}/${APP_BUNDLE}" ]]; then
    APP_PATH="${dir}/${APP_BUNDLE}"
    break
  fi
done

if [[ -z "$APP_PATH" ]]; then
  echo "Error: '${APP_BUNDLE}' not found in /Applications or ~/Applications."
  exit 1
fi

BUNDLE_ID=$(get_bundle_id "$APP_PATH")
echo "Found:     ${APP_PATH}"
[[ -n "$BUNDLE_ID" ]] && echo "Bundle ID: ${BUNDLE_ID}"
echo ""

# ── Build candidate paths ─────────────────────────────────────────────────────
CANDIDATE_DIRS=(
  # User library locations
  "${HOME}/Library/Application Support/${APP_NAME}"
  "${HOME}/Library/Caches/${APP_NAME}"
  "${HOME}/Library/Preferences/${APP_NAME}"       # folder (rare)
  "${HOME}/Library/Logs/${APP_NAME}"
  "${HOME}/Library/Saved Application State/${APP_NAME}.savedState"
  "${HOME}/Library/WebKit/${APP_NAME}"
  "${HOME}/Library/HTTPStorages/${APP_NAME}"
  # System-wide locations
  "/Library/Application Support/${APP_NAME}"
  "/Library/Preferences/${APP_NAME}"
  "/Library/Caches/${APP_NAME}"
  "/Library/Logs/${APP_NAME}"
)

CANDIDATE_FILES=(
  "${HOME}/Library/Preferences/${APP_NAME}.plist"
  "/Library/Preferences/${APP_NAME}.plist"
)

# Bundle-ID-based candidates (more reliable)
if [[ -n "$BUNDLE_ID" ]]; then
  CANDIDATE_DIRS+=(
    "${HOME}/Library/Application Support/${BUNDLE_ID}"
    "${HOME}/Library/Caches/${BUNDLE_ID}"
    "${HOME}/Library/Containers/${BUNDLE_ID}"
    "${HOME}/Library/Group Containers/${BUNDLE_ID}"
    "${HOME}/Library/Logs/${BUNDLE_ID}"
    "${HOME}/Library/HTTPStorages/${BUNDLE_ID}"
    "${HOME}/Library/WebKit/${BUNDLE_ID}"
    "${HOME}/Library/Saved Application State/${BUNDLE_ID}.savedState"
    "/Library/Application Support/${BUNDLE_ID}"
  )
  CANDIDATE_FILES+=(
    "${HOME}/Library/Preferences/${BUNDLE_ID}.plist"
    "/Library/Preferences/${BUNDLE_ID}.plist"
  )

  # Group containers use a prefix match — find them dynamically
  while IFS= read -r -d '' gc; do
    CANDIDATE_DIRS+=("$gc")
  done < <(find "${HOME}/Library/Group Containers" -maxdepth 1 -name "*${BUNDLE_ID}*" -print0 2>/dev/null)

  # LaunchAgents / LaunchDaemons
  while IFS= read -r -d '' la; do
    CANDIDATE_FILES+=("$la")
  done < <(find "${HOME}/Library/LaunchAgents" /Library/LaunchAgents /Library/LaunchDaemons \
            -maxdepth 1 -name "*${BUNDLE_ID}*" -print0 2>/dev/null)
fi

# ── Remove app bundle ─────────────────────────────────────────────────────────
echo "=== Application bundle ==="
remove_path "$APP_PATH"
echo ""

# ── Remove data directories ───────────────────────────────────────────────────
echo "=== Data directories ==="
for d in "${CANDIDATE_DIRS[@]}"; do
  remove_path "$d"
done
echo ""

# ── Remove preference/plist files ────────────────────────────────────────────
echo "=== Preferences & plists ==="
for f in "${CANDIDATE_FILES[@]}"; do
  remove_path "$f"
done
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "=== Done ==="
if [[ ${#REMOVED[@]} -gt 0 ]]; then
  echo "Removed ${#REMOVED[@]} item(s):"
  printf '  %s\n' "${REMOVED[@]}"
else
  echo "Nothing was removed."
fi
