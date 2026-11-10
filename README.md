# Quick Container Manager — releases

Built releases of the Quick Container Manager Firefox extension, and the
`updates.json` that installed copies poll to update themselves.

- `updates.json`: Firefox's self-update manifest. Each installed copy points its
  `browser_specific_settings.gecko.update_url` here and installs the newest
  version listed.
- The `.xpi` files are attached to the GitHub releases of this repo.

The extension's source is private. Releases are made with `tools/release.py`
in the source repo; do not edit `updates.json` by hand.
