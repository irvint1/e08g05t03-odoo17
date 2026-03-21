# Local Test and Manual Git-Pull Deployment

## Which compose file to use
- Use `docker-compose.yml` when you want the VM or your local machine to build from this repository.
- The main deployment stack now uses `postgres:17` so it can restore the migrated Odoo 18 backup produced by OpenUpgrade.
- Use `docker-compose.vm.yml` only for the prebuilt-image bundle workflow.
- Use `docker-compose.addons.yml` when you want the upgraded Odoo 18 helpdesk addons enabled.

## Recommended local test flow

### 1. Start with a clean smoke test
This checks that the Odoo 18 container itself starts correctly on your machine.

```powershell
docker compose -f docker-compose.yml down -v
docker compose -f docker-compose.yml up -d --build
docker compose -f docker-compose.yml ps
docker compose -f docker-compose.yml logs -f odoo
```

Then open `http://localhost:8069`.

### 1b. Start with upgraded helpdesk addons enabled
The tracked `repo-addons` directory now contains the OCA Helpdesk `18.0` code, so you can also start a fresh local stack with helpdesk modules available:

```powershell
docker compose -f docker-compose.yml -f docker-compose.addons.yml down -v
docker compose -f docker-compose.yml -f docker-compose.addons.yml up -d --build
docker compose -f docker-compose.yml -f docker-compose.addons.yml ps
docker compose -f docker-compose.yml -f docker-compose.addons.yml logs -f odoo
```

### 2. Do not use the seed dump unless it is already Odoo 18-compatible
Only use `docker-compose.seed.yml` if `odoo.sql.gz` has already been upgraded to Odoo 18.

```powershell
docker compose -f docker-compose.yml -f docker-compose.seed.yml up -d --build
```

### 3. If you want to reset everything locally
```powershell
docker compose -f docker-compose.yml down -v
```

### 4. Only enable extra addons after migrating them
The bundled helpdesk addons are now upgraded to Odoo 18. Start Odoo with them using:

```powershell
docker compose -f docker-compose.yml -f docker-compose.addons.yml up -d --build
```

## Recommended local command helper
Use [scripts/run-local.ps1](/c:/SMU/YEAR2SEM2/ESM/project/odoo-github-pipeline/scripts/run-local.ps1) on Windows.

Examples:

```powershell
.\scripts\run-local.ps1
.\scripts\run-local.ps1 -FreshDb
.\scripts\run-local.ps1 -FreshDb -WithAddons
.\scripts\run-local.ps1 -WithSeedDump -FreshDb
```

## Manual VM workflow with git pull

### 1. Clone the repo on the VM once
```bash
git clone <your-repo-url>
cd odoo-github-pipeline
```

### 2. On every change
```bash
git pull --ff-only
docker compose -f docker-compose.yml -f docker-compose.addons.yml up -d --build
docker compose -f docker-compose.yml -f docker-compose.addons.yml ps
docker compose -f docker-compose.yml -f docker-compose.addons.yml logs -f odoo
```

### 3. First-time restore from the migrated repo backup
If the repository contains the migrated Odoo 18 backup in `backup/odoo18`, use:

```bash
chmod +x scripts/restore-repo-backup.sh
./scripts/restore-repo-backup.sh
```

This does all of the following:

1. pulls the latest repo state
2. resets old Docker volumes
3. restores the committed Odoo 18 SQL backup
4. restores the committed filestore archive
5. starts Odoo 18 with the upgraded helpdesk addons

### 4. If you want a helper script for normal code-only redeploys
Use [scripts/redeploy-from-git.sh](/c:/SMU/YEAR2SEM2/ESM/project/odoo-github-pipeline/scripts/redeploy-from-git.sh).

```bash
chmod +x scripts/redeploy-from-git.sh
./scripts/redeploy-from-git.sh
```

### 5. If you need to re-import the repo backup manually
Only do this when `backup/odoo18/odoo.sql.gz` is already Odoo 18-compatible.

```bash
docker compose -f docker-compose.yml -f docker-compose.addons.yml down -v
docker compose -f docker-compose.yml -f docker-compose.addons.yml -f docker-compose.seed.yml up -d --build
```

If the repo also contains `backup/odoo18/filestore-odoo.tar.gz`, restore it into the running Odoo container:

```bash
docker exec -i odoo-app sh -lc "tar -xzf - -C /var/lib/odoo/filestore" < backup/odoo18/filestore-odoo.tar.gz
docker restart odoo-app
```

## Important limitation
- A fresh empty database is the safest first test.
- The bundled helpdesk addon code in `repo-addons/` is now on OCA `18.0`.
- Your imported database dump is still Odoo 17 until it has gone through OpenUpgrade.
- If you commit backups into git, keep the repository private and be aware that large SQL/filestore binaries can make git history grow quickly.
