param(
    [switch]$FreshDb,
    [switch]$WithSeedDump,
    [switch]$WithAddons
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$composeArgs = @("-f", "docker-compose.yml")
if ($WithAddons) {
    $composeArgs += @("-f", "docker-compose.addons.yml")
}
if ($WithSeedDump) {
    $composeArgs += @("-f", "docker-compose.seed.yml")
}

if ($FreshDb) {
    Write-Host "Removing containers and volumes first..."
    docker compose @composeArgs down -v
}

Write-Host "Building and starting Odoo..."
docker compose @composeArgs up -d --build

Write-Host ""
Write-Host "Current status:"
docker compose @composeArgs ps

Write-Host ""
Write-Host "Open http://localhost:8069"
if ($WithAddons) {
    Write-Host "Addon mode is enabled. The upgraded Odoo 18 helpdesk modules will be available to install/use."
}
if ($WithSeedDump) {
    Write-Host "Seed dump mode is enabled. Make sure odoo.sql.gz is already Odoo 18-compatible."
}
