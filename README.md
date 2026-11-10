# Quick Container Manager — releases

Built releases of the Quick Container Manager Firefox extension, and the
`updates.json` that installed copies poll to update themselves.

- `updates.json`: Firefox's self-update manifest. Each installed copy points its
  `browser_specific_settings.gecko.update_url` here and installs the newest
  version listed.
- The `.xpi` files are attached to the GitHub releases of this repo.

## Install (once per machine)

Works for a first install and for an older copy that predates self-update.
Firefox Developer Edition must have been opened at least once.

macOS / Linux (Terminal):

```
curl -fsSL https://raw.githubusercontent.com/aaronvstory/qcm-releases/main/install.sh | sh
```

Windows (PowerShell):

```
irm https://raw.githubusercontent.com/aaronvstory/qcm-releases/main/install.ps1 | iex
```

Both download the newest release, check its sha256 against `updates.json`, and
drop it into every Developer Edition profile. Restart Firefox Developer Edition
afterwards. From then on the extension updates itself.

The extension's source is private. Releases are made with `tools/release.py`
in the source repo; do not edit `updates.json` by hand.
