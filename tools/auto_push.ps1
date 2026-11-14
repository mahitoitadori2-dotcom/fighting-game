# Commits and pushes everything in the Universal Beatdown repo that is meant to be public
# (everything .gitignore allows), then prints a one-line JSON result for Claude Code.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/auto_push.ps1 [-Message "text"]
#
# Used by the /push command and by the Claude Code Stop hook (runs when Claude finishes).
# Safety:
#   - Files that look like secrets (.env, keys, certificates, credentials) are never committed.
#   - Does nothing while a merge / rebase is in progress or on a detached HEAD.
#   - Never pushes a game with SCRIPT ERRORS: when scripts changed, Godot compiles the project
#     first; on a parse / compile error the commit stays local and nothing is pushed.
#   - Pulls GitHub's newer commits first (rebase). On a conflict it aborts, keeps the commit
#     locally and reports it instead of forcing anything. Never force-pushes.
param([string]$Message = "")

$ErrorActionPreference = "Continue"
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Run-Git([string[]]$GitArgs) {
	$out = & git @GitArgs 2>&1 | ForEach-Object { "$_" }
	return @{ code = $LASTEXITCODE; out = ($out -join "`n").Trim() }
}

function Finish([string]$text) {
	@{ systemMessage = "Auto-push: $text" } | ConvertTo-Json -Compress
	exit 0
}

if (-not (Test-Path (Join-Path $repo ".git"))) { Finish "not a git repository ($repo), skipped." }
$gitDir = Join-Path $repo ".git"
if ((Test-Path "$gitDir/MERGE_HEAD") -or (Test-Path "$gitDir/rebase-merge") -or (Test-Path "$gitDir/rebase-apply")) {
	Finish "a merge or rebase is in progress, skipped. Finish it first."
}
$branch = (Run-Git @("rev-parse", "--abbrev-ref", "HEAD")).out
if ($branch -eq "HEAD" -or $branch -eq "") { Finish "detached HEAD, skipped." }

# ---- Stage everything .gitignore allows, minus anything that looks like a secret ----
$null = Run-Git @("add", "-A")
$secretPattern = '(^|/)(\.env(\..*)?|id_rsa.*|id_ed25519.*|.*\.(pem|key|p12|pfx|keystore|jks)|.*credential.*|.*secret.*|export_credentials\.cfg)$'
$staged = (Run-Git @("diff", "--cached", "--name-only")).out -split "`n" | Where-Object { $_ -ne "" }
$blocked = @($staged | Where-Object { $_.ToLower() -match $secretPattern })
foreach ($f in $blocked) { $null = Run-Git @("reset", "-q", "HEAD", "--", $f) }
$staged = @($staged | Where-Object { $blocked -notcontains $_ })
$note = ""
if ($blocked.Count -gt 0) { $note = " NOT committed (look like secrets): " + ($blocked -join ", ") + "." }

# ---- Commit ----
$committed = $false
if ($staged.Count -gt 0) {
	if ($Message -eq "") {
		$names = @($staged | Select-Object -First 4 | ForEach-Object { Split-Path $_ -Leaf })
		$more = if ($staged.Count -gt 4) { " +$($staged.Count - 4) more" } else { "" }
		$Message = "Auto-commit: " + ($names -join ", ") + $more
	}
	$c = Run-Git @("commit", "-q", "-m", $Message)
	if ($c.code -ne 0) { Finish "commit failed: $($c.out)$note" }
	$committed = $true
}

# ---- Anything to push? ----
$null = Run-Git @("fetch", "-q", "origin", $branch)
$ahead = [int]((Run-Git @("rev-list", "--count", "origin/$branch..HEAD")).out)
if ($ahead -eq 0) {
	if ($note -ne "") { Finish "nothing to push.$note" }
	exit 0                                                     # Clean and up to date: stay silent
}

# ---- Bring in GitHub's newer commits, then push ----
$behind = [int]((Run-Git @("rev-list", "--count", "HEAD..origin/$branch")).out)
if ($behind -gt 0) {
	$r = Run-Git @("rebase", "-q", "origin/$branch")
	if ($r.code -ne 0) {
		$null = Run-Git @("rebase", "--abort")
		Finish "NOT pushed: GitHub has $behind newer commit(s) that conflict with yours. Your work is committed locally; merge origin/$branch by hand, then run /push.$note"
	}
}
# ---- Never push a game that doesn't compile ----
# If scripts / scenes / project settings changed, compile the project with Godot first. Any parse
# or compile error = NOT pushed (the website would break). The commit stays local; fix the error
# and the next push sends it. Skipped when the Godot console exe is not found (GODOT env or default).
$changed = (Run-Git @("diff", "--name-only", "origin/$branch..HEAD")).out -split "`n" | Where-Object { $_ -match '\.(gd|tscn|tres|godot)$' }
$godot = if ($env:GODOT) { $env:GODOT } else { "C:/code/Godot_v4.7.2-stable_win64_console.exe" }
# Scene / resource files that start with a UTF-8 BOM don't parse ("Parse Error: Expected '['")
$bom = @($changed | Where-Object { $_ -match '\.(tscn|tres|godot)$' -and (Test-Path (Join-Path $repo $_)) } | Where-Object {
	$b = [IO.File]::ReadAllBytes((Join-Path $repo $_)); $b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF })
if ($bom.Count -gt 0) {
	Finish ("NOT pushed: these files start with a BOM and Godot can't parse them (save as UTF-8 without BOM): " + ($bom -join ", ") + $note)
}
if ($changed.Count -gt 0 -and (Test-Path $godot)) {
	$null = & $godot --headless --path $repo --import 2>&1                  # Register new / renamed classes first
	$log = & $godot --headless --path $repo "res://tools/check_scripts.tscn" 2>&1 | ForEach-Object { "$_" }
	$bad = @($log | Where-Object { $_ -match '^SCRIPT FAIL: (.+)$' } | ForEach-Object { $_ -replace '^SCRIPT FAIL: res://', '' })
	if ($bad.Count -gt 0) {
		Finish ("NOT pushed: $($bad.Count) script(s) don't compile, the website would break. Committed locally only - fix and push again: " + (($bad | Select-Object -First 5) -join ", ") + $note)
	}
}
$p = Run-Git @("push", "-q", "origin", $branch)
if ($p.code -ne 0) { Finish "push failed: $($p.out)$note" }
$head = (Run-Git @("log", "-1", "--format=%h %s")).out
Finish ("pushed $ahead commit(s) to origin/$branch" + $(if ($committed) { " (new: $head)" } else { "" }) + ".$note")
