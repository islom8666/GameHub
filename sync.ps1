param(
    [string]$Message = ("Update " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
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
if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit bajarilmadi. Yuqoridagi xatoni o'qing." -ForegroundColor Red
    exit 1
}

git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "GitHub'ga YUKLANMADI." -ForegroundColor Red
    Write-Host "Agar yuqorida 'rejected / fetch first' bo'lsa, avval shuni bajaring:" -ForegroundColor Yellow
    Write-Host "    git pull --rebase origin main" -ForegroundColor Yellow
    Write-Host "keyin yana .\sync.ps1 ni ishga tushiring." -ForegroundColor Yellow
    exit 1
}

Write-Host "Tayyor! GitHub'ga yuklandi." -ForegroundColor Green
