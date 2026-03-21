# VM Deployment from Repo

This is the recommended flow now that the Odoo 17 database has already been migrated locally to Odoo 18.

## Goal

Push everything needed into the repository so the VM can:

1. `git pull`
2. restore the migrated Odoo 18 database backup
3. restore the filestore
4. start Odoo 18 with the upgraded helpdesk addons

## Files used for this flow

1. `backup/odoo18/odoo.sql.gz`
2. `backup/odoo18/filestore-odoo.tar.gz`
3. `docker-compose.yml`
4. `docker-compose.addons.yml`
5. `docker-compose.seed.yml`
6. `scripts/restore-repo-backup.sh`
7. `scripts/redeploy-from-git.sh`

## On your local machine

After you finish testing the migrated database locally, export it into the repo:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-migrated-backup.ps1 -DbName odoo
```

That writes these repo-tracked files:

1. `backup/odoo18/odoo.sql.gz`
2. `backup/odoo18/filestore-odoo.tar.gz`
3. `backup/odoo18/README.md`

Then commit and push:

```powershell
git add backup/odoo18 docker-compose.seed.yml scripts/export-migrated-backup.ps1 scripts/restore-repo-backup.sh scripts/redeploy-from-git.sh MANUAL_DEPLOY.md VM_REPO_DEPLOY.md
git commit -m "Add repo-based Odoo 18 backup deployment flow"
git push
```

## On the VM

Clone once:

```bash
git clone <your-repo-url>
cd odoo-github-pipeline
chmod +x scripts/restore-repo-backup.sh scripts/redeploy-from-git.sh scripts/install-vm-autostart.sh
```

First restore from the committed backup:

```bash
./scripts/restore-repo-backup.sh
```

Open:

```text
http://<vm-ip>:8069
```

## Make it start again after VM reboot

The compose file already uses `restart: unless-stopped`, but that only helps after the containers exist. To make the compose stack itself come back reliably after reboot, install the VM boot service:

```bash
./scripts/install-vm-autostart.sh
```

Then verify:

```bash
sudo systemctl status odoo-compose.service
docker compose -f docker-compose.yml -f docker-compose.addons.yml ps
```

If you ever move the repo to a different path on the VM, rerun the install script so the service points at the new location.

## On later code-only updates

If the database contents are not changing and you only changed code or addons:

```bash
./scripts/redeploy-from-git.sh
```

## When to re-export the backup

Re-export and recommit the backup only when the database contents changed and you want those changes deployed to the VM too.

If you only changed Python/XML/views/addons code, do not re-export the backup. Just push the code and use the normal redeploy script.

## Important caution

Committing backups into git is convenient, but it has tradeoffs:

1. the repo should stay private
2. git history can become heavy if you commit many large backups
3. database backups may contain sensitive data

For your current goal, this is acceptable as long as you treat the repo like a private deployment repository.
