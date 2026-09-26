# Shepherd CLI Universal Installer for Windows PowerShell
# Marmelotech - https://marmelotech.com.br
$ErrorActionPreference = "Stop"

$Repo = "cruvinelrv/shepherd"
$InstallDir = "$HOME\.shepherd\bin"

Write-Host "🐑 Instalando Shepherd CLI no Windows..." -ForegroundColor Cyan

# Fetch latest release tag
try {
    $Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
    $LatestTag = $Release.tag_name
} catch {
    $LatestTag = "v0.11.2"
}

$ZipUrl = "https://github.com/$Repo/releases/download/$LatestTag/shepherd-windows-x64.zip"
$TempZip = "$env:TEMP\shepherd-windows-x64.zip"
$TempExtract = "$env:TEMP\shepherd_extracted"

Write-Host "⬇️  Baixando Shepherd ($LatestTag)..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

if (Test-Path $TempExtract) {
    Remove-Item -Recurse -Force $TempExtract
}

Write-Host "📦 Extraindo executável..." -ForegroundColor Yellow
Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
Move-Item -Path "$TempExtract\shepherd.exe" -Destination "$InstallDir\shepherd.exe" -Force

Remove-Item -Force $TempZip
Remove-Item -Recurse -Force $TempExtract

# Add to User PATH if not present
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$InstallDir*") {
    Write-Host "⚙️  Adicionando $InstallDir ao PATH do usuário..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
    $env:Path += ";$InstallDir"
}

Write-Host "✅ Shepherd CLI instalado com sucesso em $InstallDir\shepherd.exe!" -ForegroundColor Green
Write-Host "🚀 Execute 'shepherd' no seu terminal para começar." -ForegroundColor Green
