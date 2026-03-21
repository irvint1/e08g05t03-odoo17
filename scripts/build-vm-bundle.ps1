param(
    [string]$ImageName = "odoo-erp:18.0-bundle",
    [string]$BundleName = "odoo18-vm-bundle"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$distDir = Join-Path $root "dist"
$bundleDir = Join-Path $distDir $BundleName
$zipPath = Join-Path $distDir ($BundleName + ".zip")
$imageTar = Join-Path $bundleDir "odoo18-image.tar"

Write-Host "[1/6] Checking Docker daemon"
docker info | Out-Null

Write-Host "[2/6] Rebuilding bundle folder"
if (Test-Path $bundleDir) {
    Remove-Item -Recurse -Force $bundleDir
}
New-Item -ItemType Directory -Path $bundleDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $bundleDir "docker\\initdb") | Out-Null
New-Item -ItemType Directory -Path (Join-Path $bundleDir "scripts") | Out-Null

Write-Host "[3/6] Building Odoo 18 image: $ImageName"
docker build -t $ImageName -f (Join-Path $root "Dockerfile") $root

Write-Host "[4/6] Saving image tar"
docker save -o $imageTar $ImageName

Write-Host "[5/6] Copying runtime files"
Copy-Item (Join-Path $root "docker-compose.vm.yml") $bundleDir
Copy-Item (Join-Path $root "docker-compose.seed.yml") $bundleDir
Copy-Item (Join-Path $root ".env.vm.example") $bundleDir
Copy-Item (Join-Path $root "DOCKER_VM_RUN.md") $bundleDir
Copy-Item (Join-Path $root "ODOO18_MIGRATION.md") $bundleDir
Copy-Item (Join-Path $root "docker\\odoo.conf") (Join-Path $bundleDir "docker\\odoo.conf")
Copy-Item (Join-Path $root "docker\\initdb\\00-create-legacy-role.sql") (Join-Path $bundleDir "docker\\initdb\\00-create-legacy-role.sql")
Copy-Item (Join-Path $root "scripts\\start-odoo-vm.sh") (Join-Path $bundleDir "scripts\\start-odoo-vm.sh")

if (Test-Path (Join-Path $root "odoo.sql.gz")) {
    Copy-Item (Join-Path $root "odoo.sql.gz") $bundleDir
}

Write-Host "[6/6] Creating zip archive"
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path (Join-Path $bundleDir "*") -DestinationPath $zipPath

Write-Host ""
Write-Host "Bundle ready:"
Write-Host "Folder: $bundleDir"
Write-Host "Zip:    $zipPath"
