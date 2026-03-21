param(
    [Parameter(Mandatory = $true)]
    [string]$DumpPath,

    [string]$DbName = "odoo17_openupgrade",

    [string]$FilestorePath,

    [switch]$Fresh
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$projectName = "openupgrade18"
$composeArgs = @("-p", $projectName, "-f", "docker-compose.openupgrade.yml")
$dump = Resolve-Path $DumpPath
$dumpName = Split-Path $dump -Leaf
$odooDataDir = Join-Path $root "migration-data\openupgrade\odoo"

function Assert-LastExit {
    param(
        [string]$Context
    )

    if ($LASTEXITCODE -ne 0) {
        throw "$Context failed with exit code $LASTEXITCODE."
    }
}

function Wait-ForDb {
    $attempt = 0
    while ($attempt -lt 60) {
        $dbContainer = docker compose @composeArgs ps -q db
        if ($dbContainer) {
            $status = docker inspect --format "{{.State.Health.Status}}" $dbContainer 2>$null
            if ($LASTEXITCODE -eq 0 -and $status.Trim() -eq "healthy") {
                return $dbContainer
            }
        }

        Start-Sleep -Seconds 2
        $attempt++
    }

    throw "OpenUpgrade Postgres did not become healthy in time."
}

if ($Fresh) {
    Write-Host "Removing previous OpenUpgrade containers and data..."
    docker compose @composeArgs down -v --remove-orphans
    Assert-LastExit "docker compose down"
    Remove-Item $odooDataDir -Recurse -Force -ErrorAction SilentlyContinue
}

New-Item -ItemType Directory -Force $odooDataDir | Out-Null

if ($FilestorePath) {
    $filestore = Resolve-Path $FilestorePath
    $targetFilestore = Join-Path $odooDataDir "filestore\$DbName"

    Write-Host "Copying filestore into $targetFilestore ..."
    Remove-Item $targetFilestore -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force $targetFilestore | Out-Null
    Copy-Item (Join-Path $filestore "*") $targetFilestore -Recurse -Force
}

Write-Host "Starting OpenUpgrade Postgres..."
docker compose @composeArgs up -d --build db
Assert-LastExit "docker compose up db"

$dbContainer = Wait-ForDb

Write-Host "Copying dump into the Postgres container..."
docker cp $dump "${dbContainer}:/tmp/$dumpName"
Assert-LastExit "docker cp dump"

Write-Host "Recreating database $DbName ..."
docker exec $dbContainer dropdb --if-exists -U odoo $DbName
Assert-LastExit "dropdb"
docker exec $dbContainer createdb -U odoo -O odoo $DbName
Assert-LastExit "createdb"

$lowerName = $dumpName.ToLowerInvariant()
if ($lowerName.EndsWith(".dump") -or $lowerName.EndsWith(".backup")) {
    Write-Host "Restoring custom-format dump..."
    docker exec $dbContainer pg_restore --no-owner --no-privileges --role=odoo -U odoo -d $DbName "/tmp/$dumpName"
    Assert-LastExit "pg_restore"
} elseif ($lowerName.EndsWith(".sql")) {
    Write-Host "Restoring SQL dump..."
    docker exec $dbContainer psql -U odoo -d $DbName -f "/tmp/$dumpName"
    Assert-LastExit "psql restore"
} elseif ($lowerName.EndsWith(".sql.gz")) {
    Write-Host "Restoring gzipped SQL dump..."
    docker exec $dbContainer sh -lc "gunzip -c /tmp/$dumpName | psql -U odoo -d $DbName"
    Assert-LastExit "gunzip/psql restore"
} else {
    throw "Unsupported dump format. Use .dump, .backup, .sql, or .sql.gz."
}

Write-Host "Running OpenUpgrade 17.0 -> 18.0 ..."
docker compose @composeArgs run --rm openupgrade `
    odoo `
    -c /etc/odoo/openupgrade.conf `
    --upgrade-path=/opt/openupgrade/openupgrade_scripts/scripts `
    --load=base,web,openupgrade_framework `
    --update=all `
    --stop-after-init `
    -d $DbName
Assert-LastExit "OpenUpgrade run"

Write-Host ""
Write-Host "OpenUpgrade finished. Review the logs above carefully."
Write-Host "If it completed successfully, the migrated database is still inside the OpenUpgrade Postgres service under the name $DbName."
Write-Host "Next, either export that upgraded DB or restore it into your normal Odoo 18 stack for testing."
