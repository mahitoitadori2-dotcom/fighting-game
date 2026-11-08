# Commits and pushes everything in the Universal Beatdown repo that is meant to be public
# (everything .gitignore allows), then prints a one-line JSON result for Claude Code.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/auto_push.ps1 [-Message "text"]
#
# Used by the /push command and by the Claude Code Stop hook (runs when Claude finishes).
# Safety:
#   - Files that look like secrets (.env, keys, certificates, credentials) are never committed.
#   - Does nothing while a merge / rebase is in progress or on a detached HEAD.
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
$p = Run-Git @("push", "-q", "origin", $branch)
if ($p.code -ne 0) { Finish "push failed: $($p.out)$note" }
$head = (Run-Git @("log", "-1", "--format=%h %s")).out
Finish ("pushed $ahead commit(s) to origin/$branch" + $(if ($committed) { " (new: $head)" } else { "" }) + ".$note")
