# Install (or update) Quick Container Manager into Firefox Developer Edition on
# Windows, from the newest published release. One line in PowerShell:
#
#   irm https://raw.githubusercontent.com/aaronvstory/qcm-releases/main/install.ps1 | iex
#
# Then restart Firefox Developer Edition. From then on the extension updates
# itself (it checks this repo's updates.json about once a day).
$ErrorActionPreference = 'Stop'
$id   = 'quick-container-manager@local'
$base = 'https://raw.githubusercontent.com/aaronvstory/qcm-releases/main'
$ff   = Join-Path $env:APPDATA 'Mozilla/Firefox'

# 1. The Dev Edition profiles (dev-edition-default, dev-edition-default-1, ...).
$ini  = Get-Content (Join-Path $ff 'profiles.ini') -ErrorAction SilentlyContinue
$rels = @($ini | Select-String '^Path=(.*dev-edition-default(-\d+)?)$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
if (-not $rels) { throw 'No dev-edition-default profile. Launch Firefox Developer Edition once, close it, then re-run.' }

# 2. The newest release: updates.json lists it first, with its sha256.
$u    = (Invoke-RestMethod "$base/updates.json").addons.$id.updates[0]
$want = ($u.update_hash -replace '^sha256:', '').ToUpper()
$tmp  = Join-Path ([IO.Path]::GetTempPath()) "qcm-$([guid]::NewGuid().ToString('N')).xpi"
try {
  Invoke-WebRequest $u.update_link -OutFile $tmp -UseBasicParsing
  if ((Get-FileHash $tmp -Algorithm SHA256).Hash -ne $want) { throw 'Download does not match the published sha256.' }
  foreach ($rel in $rels) {
    $prof = if ([IO.Path]::IsPathRooted($rel)) { $rel } else { Join-Path $ff $rel }
    if (-not (Test-Path $prof)) { continue }
    # 3. Allow unsigned add-ons and auto-enable ones dropped into the profile.
    $userJs = Join-Path $prof 'user.js'
    $have = if (Test-Path $userJs) { @(Get-Content $userJs) } else { @() }
    foreach ($pref in 'user_pref("xpinstall.signatures.required", false);',
                      'user_pref("extensions.autoDisableScopes", 0);') {
      if ($have -notcontains $pref) { Add-Content $userJs $pref -Encoding ascii }
    }
    # 4. Drop it in. Firefox loads it on its next start.
    New-Item -ItemType Directory -Force (Join-Path $prof 'extensions') | Out-Null
    Copy-Item $tmp (Join-Path $prof "extensions/$id.xpi") -Force
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Installed $id $($u.version) into $prof"
  }
} finally {
  Remove-Item $tmp -ErrorAction SilentlyContinue
}
Write-Host 'Restart Firefox Developer Edition to load it.'
