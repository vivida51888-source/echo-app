# Push echo-app to GitHub (Vivida/echo-app) and enable GitHub Pages via docs/
# Run from project root: powershell -ExecutionPolicy Bypass -File scripts\push-to-github.ps1

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$GitHubUser = "Vivida"
$RepoName = "echo-app"
$RemoteUrl = "https://github.com/$GitHubUser/$RepoName.git"

function Find-Git {
    $candidates = @(
        "git",
        "$env:ProgramFiles\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe",
        "$RepoRoot\.tools\mingit\cmd\git.exe"
    )
    foreach ($c in $candidates) {
        if ($c -eq "git") {
            $cmd = Get-Command git -ErrorAction SilentlyContinue
            if ($cmd) { return $cmd.Source }
        } elseif (Test-Path $c) { return $c }
    }
    throw "Git not found. Install from https://git-scm.com/download/win then re-run this script."
}

$git = Find-Git
Write-Host "Using git: $git"

if (-not (Test-Path ".git")) {
    & $git init
    & $git branch -M main
}

$remote = & $git remote get-url origin 2>$null
if (-not $remote) {
    & $git remote add origin $RemoteUrl
} elseif ($remote -ne $RemoteUrl) {
    & $git remote set-url origin $RemoteUrl
}

& $git add -A
$status = & $git status --porcelain
if ($status) {
    $msg = "Initial commit: Echo app and privacy policy for GitHub Pages."
    & $git -c "user.name=$GitHubUser" -c "user.email=vivida51888@gmail.com" commit -m $msg
    Write-Host "Committed changes."
} else {
    Write-Host "Nothing to commit."
}

Write-Host ""
Write-Host "Pushing to $RemoteUrl ..."
Write-Host "If prompted, sign in with your GitHub account or Personal Access Token."
& $git push -u origin main

Write-Host ""
Write-Host "Done. Enable GitHub Pages:"
Write-Host "  https://github.com/$GitHubUser/$RepoName/settings/pages"
Write-Host "  Source: branch main, folder /docs"
Write-Host ""
Write-Host "Privacy policy URLs:"
Write-Host "  https://$($GitHubUser.ToLower()).github.io/$RepoName/"
Write-Host "  https://$($GitHubUser.ToLower()).github.io/$RepoName/privacy.html"
