# Shepherd CLI Universal Installer for Windows PowerShell
# Marmelotech - https://marmelo.tech
$ErrorActionPreference = "Stop"

$Repo = "cruvinelrv/shepherd"
$InstallDir = "$HOME\.shepherd\bin"

Write-Host "🐑 Installing Shepherd CLI on Windows..." -ForegroundColor Cyan

# Fetch latest release tag
try {
    $Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
    $LatestTag = $Release.tag_name
} catch {
    # GitHub's API could not be reached: take the latest release anyway.
    $LatestTag = "latest"
}

if ($LatestTag -eq "latest") {
    $ZipUrl = "https://github.com/$Repo/releases/latest/download/shepherd-windows-x64.zip"
} else {
    $ZipUrl = "https://github.com/$Repo/releases/download/$LatestTag/shepherd-windows-x64.zip"
}
$TempZip = "$env:TEMP\shepherd-windows-x64.zip"
$TempExtract = "$env:TEMP\shepherd_extracted"

Write-Host "⬇️  Downloading Shepherd ($LatestTag)..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

if (Test-Path $TempExtract) {
    Remove-Item -Recurse -Force $TempExtract
}

Write-Host "📦 Extracting the executable and native libraries..." -ForegroundColor Yellow
Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force

if (Test-Path "$TempExtract\lib") {
    $LibDir = "$HOME\.shepherd\lib"
    if (-not (Test-Path $LibDir)) { New-Item -ItemType Directory -Path $LibDir -Force | Out-Null }
    Copy-Item -Path "$TempExtract\lib\*" -Destination $LibDir -Recurse -Force
}

if (Test-Path "$TempExtract\bin\shepherd.exe") {
    Copy-Item -Path "$TempExtract\bin\shepherd.exe" -Destination "$InstallDir\shepherd.exe" -Force
} elseif (Test-Path "$TempExtract\shepherd.exe") {
    Copy-Item -Path "$TempExtract\shepherd.exe" -Destination "$InstallDir\shepherd.exe" -Force
}

Remove-Item -Force $TempZip
Remove-Item -Recurse -Force $TempExtract

# Add to User PATH if not present
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$InstallDir*") {
    Write-Host "⚙️  Adding $InstallDir to your user PATH..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
    $env:Path += ";$InstallDir"
}

Write-Host "✅ Shepherd CLI installed at $InstallDir\shepherd.exe!" -ForegroundColor Green
Write-Host "🚀 Run 'shepherd' in your terminal to start. Change the language with 'shepherd lang pt' or 'shepherd lang es'." -ForegroundColor Green
