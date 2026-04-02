# commit-all.ps1
# Commitne aktualni projekt + aktualizaci knowledge base zaroven
# Parametry:
#   -ProjectPath  cesta k projektu (napr. D:\git\rezervace-app)
#   -Message      commit zprava
#
# Pouziti:
#   .\commit-all.ps1 -ProjectPath "D:\git\rezervace-app" -Message "feat: nova funkce"

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [Parameter(Mandatory=$true)]
    [string]$Message
)

$kbPath = "D:\git\dev-knowledge-base"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Commit: projekt + knowledge base" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# --- Projekt ---
Write-Host "1. Projekt: $ProjectPath" -ForegroundColor Yellow
Set-Location $ProjectPath
git add .
git commit --allow-empty -m $Message
git push
$hash = git log --oneline -1
Write-Host "[OK] $hash" -ForegroundColor Green

# --- Knowledge Base ---
Write-Host "`n2. Knowledge Base: $kbPath" -ForegroundColor Yellow
Set-Location $kbPath
git add knowledge-base.md
git commit --allow-empty -m "update: sync s $((Split-Path $ProjectPath -Leaf)) - $Message"
git push
$kbHash = git log --oneline -1
Write-Host "[OK] $kbHash" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Hotovo. Oba repozitare commitnuty." -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
