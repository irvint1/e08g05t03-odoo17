param(
    [string]$DbName = "odoo",
    [string]$OutputDir = "backup/odoo18",
    [string]$ProjectName = "openupgrade18"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$composeArgs = @("-p", $ProjectName, "-f", "docker-compose.openupgrade.yml")
$dbCid = docker compose @composeArgs ps -q db
if (-not $dbCid) {
    throw "OpenUpgrade Postgres container is not running. Run the migration first."
}

$outputPath = Join-Path $root $OutputDir
$sqlPath = Join-Path $outputPath "odoo.sql.gz"
$filestoreSource = Join-Path $root "migration-data\openupgrade\odoo\filestore\$DbName"
$filestoreArchive = Join-Path $outputPath "filestore-$DbName.tar.gz"
$metadataPath = Join-Path $outputPath "README.md"

if (-not (Test-Path $filestoreSource)) {
    throw "Filestore path not found: $filestoreSource"
}

New-Item -ItemType Directory -Force $outputPath | Out-Null

Write-Host "Exporting migrated database $DbName to $sqlPath ..."
docker exec $dbCid sh -lc "pg_dump -U odoo -C -Fp '$DbName' | gzip -9 > /tmp/odoo.sql.gz"
if ($LASTEXITCODE -ne 0) {
    throw "pg_dump export failed."
}

docker cp "${dbCid}:/tmp/odoo.sql.gz" $sqlPath
if ($LASTEXITCODE -ne 0) {
    throw "Copying odoo.sql.gz from container failed."
}

Write-Host "Archiving filestore from $filestoreSource to $filestoreArchive ..."
if (Test-Path $filestoreArchive) {
    Remove-Item $filestoreArchive -Force
}
tar -czf $filestoreArchive -C (Split-Path $filestoreSource -Parent) $DbName
if ($LASTEXITCODE -ne 0) {
    throw "Creating filestore archive failed."
}

$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
@"
# Odoo 18 Repo Backup

Generated from the OpenUpgrade migration flow in this repository.

- Database name: `$DbName`
- Generated at: `$generatedAt`
- SQL backup: `odoo.sql.gz`
- Filestore archive: `filestore-$DbName.tar.gz`

Use `scripts/restore-repo-backup.sh` on the VM to restore this backup into a fresh Docker volume.
"@ | Set-Content -Path $metadataPath -Encoding ASCII

Write-Host ""
Write-Host "Backup export completed."
Write-Host "Files written:"
Write-Host " - $sqlPath"
Write-Host " - $filestoreArchive"
Write-Host " - $metadataPath"
