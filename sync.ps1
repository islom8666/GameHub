param(
    [string]$Message = "Auto update 2026-11-26 23:09"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

git add .
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "Yangi o'zgarish topilmadi." -ForegroundColor Yellow
    exit 0
}

git commit -m "$Message"
git push origin main
Write-Host "Tayyor! GitHub'ga yuklandi." -ForegroundColor Green
