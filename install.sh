#!/bin/sh
# Install (or update) Quick Container Manager into Firefox Developer Edition on
# macOS or Linux, from the newest published release. One line:
#
#   curl -fsSL https://raw.githubusercontent.com/aaronvstory/qcm-releases/main/install.sh | sh
#
# Then restart Firefox Developer Edition. From then on the extension updates
# itself (it checks this repo's updates.json about once a day).
set -eu
id='quick-container-manager@local'
base='https://raw.githubusercontent.com/aaronvstory/qcm-releases/main'

case "$(uname)" in
  Darwin) ffdir="$HOME/Library/Application Support/Firefox" ;;
  *)      ffdir="$HOME/.mozilla/firefox" ;;
esac

# 1. The Dev Edition profiles (dev-edition-default, dev-edition-default-1, ...).
#    The one it opens is not always the first, so install into all of them.
rels=$(sed -n 's/^Path=\(.*dev-edition-default\(-[0-9]*\)\{0,1\}\)\r\{0,1\}$/\1/p' "$ffdir/profiles.ini" 2>/dev/null || true)
[ -n "$rels" ] || { echo 'No dev-edition-default profile. Launch Firefox Developer Edition once, quit it, then re-run.' >&2; exit 1; }

# 2. The newest release: updates.json lists it first, with its sha256.
json=$(curl -fsSL "$base/updates.json")
link=$(printf '%s\n' "$json" | sed -n 's/.*"update_link": *"\([^"]*\)".*/\1/p' | head -n 1)
want=$(printf '%s\n' "$json" | sed -n 's/.*"update_hash": *"sha256:\([0-9a-f]*\)".*/\1/p' | head -n 1)
ver=$(printf '%s\n' "$json" | sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' | head -n 1)
[ -n "$link" ] && [ -n "$want" ] || { echo 'Could not read updates.json.' >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/qcm.xpi" "$link"
if command -v shasum >/dev/null 2>&1; then got=$(shasum -a 256 "$tmp/qcm.xpi" | cut -d' ' -f1)
else got=$(sha256sum "$tmp/qcm.xpi" | cut -d' ' -f1); fi
[ "$got" = "$want" ] || { echo "Download does not match the published sha256 ($got)." >&2; exit 1; }

echo "$rels" | while IFS= read -r rel; do
  case "$rel" in /*|[A-Za-z]:*) prof="$rel" ;; *) prof="$ffdir/$rel" ;; esac
  [ -d "$prof" ] || continue
  # 3. Allow unsigned add-ons and auto-enable ones dropped into the profile.
  #    Append only what is missing, so prefs already in user.js survive.
  for pref in 'user_pref("xpinstall.signatures.required", false);' \
              'user_pref("extensions.autoDisableScopes", 0);'; do
    grep -qxF "$pref" "$prof/user.js" 2>/dev/null || printf '%s\n' "$pref" >> "$prof/user.js"
  done
  # 4. Drop it in. Firefox loads it on its next start.
  mkdir -p "$prof/extensions"
  cp "$tmp/qcm.xpi" "$prof/extensions/$id.xpi"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installed $id $ver into $prof"
done
echo 'Restart Firefox Developer Edition to load it.'
