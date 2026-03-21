# Odoo 17 to Odoo 18 Migration with OCA/OpenUpgrade

This repo now has two separate local lanes:

1. The normal Odoo 18 app lane you already tested successfully.
2. A separate OpenUpgrade lane for transforming an Odoo 17 database into an Odoo 18 database.

Keep them separate. That makes troubleshooting much easier.

## Is this possible?

Yes, in principle.

OpenUpgrade supports the 17.0 -> 18.0 jump, but it does not mean every database will migrate cleanly on the first try.

Important realities:

1. Your source code for custom or OCA addons must already be updated to the target version before the database migration is attempted.
2. OpenUpgrade mainly covers Odoo's standard modules. OCA or custom addons rely on migration scripts that live in their own module repositories.
3. You should migrate from a copy of your Odoo 17 database, never from the live production database.
4. You should also keep a copy of the Odoo 17 filestore if you want attachments and documents to remain available after the migration.

## What is already in place in this repo

Your tracked helpdesk addon directory `repo-addons` already contains the OCA Helpdesk `18.0` code.

For the helpdesk modules you installed earlier, local migration coverage currently looks like this:

1. `helpdesk_mgmt`: has `migrations/18.0.1.7.0/post-migration.py`
2. `helpdesk_mgmt_project`: has `migrations/18.0.1.0.0/post-migration.py` and `migrations/18.0.1.1.0/pre-migration.py`
3. `helpdesk_mgmt_merge`: no migration directory
4. `helpdesk_mgmt_sale`: no migration directory
5. `helpdesk_ticket_related`: no migration directory
6. `helpdesk_type`: no migration directory

That does not automatically mean the modules without migration folders will fail, but it does mean we should test them carefully.

## What you need before you start

Prepare these inputs first:

1. An Odoo 17 database dump.
2. The Odoo 17 filestore folder for that same database, if you need attachments.
3. A clean local working copy of this repo.
4. Docker Desktop running.

For filestore, use the database-specific folder, for example:

```text
filestore/<your_db_name>
```

Do not point to the whole Odoo data directory unless that folder itself contains the correct filestore contents for the database you are migrating.

## How to run the migration locally

Use the new helper script:

```powershell
.\scripts\run-openupgrade.ps1 `
  -DumpPath "C:\SMU\YEAR2SEM2\ESM\project\odoo_2026-03-21_03-35-00.dump" `
  -DbName "odoo17_ou18" `
  -FilestorePath "C:\path\to\filestore\your_db_name" `
  -Fresh
```

What that script does:

1. Starts a separate Postgres container for OpenUpgrade.
2. Restores your Odoo 17 dump into a fresh database copy.
3. Copies the filestore into the OpenUpgrade Odoo data directory, if you provide one.
4. Runs OpenUpgrade 18.0 against that copied database.

## What to expect during the migration

A successful migration usually takes a few rounds, not one perfect pass.

If OpenUpgrade stops with an error, the normal process is:

1. Read the failing module or failing field from the logs.
2. Fix the target addon code or add a migration script.
3. Re-run from a fresh copy of the Odoo 17 dump.

Typical failure categories:

1. A custom or OCA module has no migration logic for a changed schema.
2. The database contains data that violates a new required field or constraint.
3. A module was renamed, merged, or removed between versions.
4. Old records or XML IDs need remapping.

## After OpenUpgrade finishes

If the migration succeeds, the upgraded database stays inside the OpenUpgrade Postgres service.

To export that upgraded database:

```powershell
$compose = @("-p", "openupgrade18", "-f", "docker-compose.openupgrade.yml")
$dbCid = docker compose @compose ps -q db
docker exec $dbCid pg_dump -Fc -U odoo -d odoo17_ou18 -f /tmp/odoo18_migrated.dump
docker cp "${dbCid}:/tmp/odoo18_migrated.dump" ".\migration-data\openupgrade\odoo18_migrated.dump"
```

Then restore it into your normal Odoo 18 stack and test it there with:

```powershell
.\scripts\run-local.ps1 -FreshDb -WithAddons
```

If you also migrated the filestore, keep the same database name when you test in the normal Odoo 18 stack. That avoids attachment path mismatches.

## Recommended order for you

For your project, the safest sequence is:

1. Keep your working fresh Odoo 18 helpdesk test DB untouched.
2. Run OpenUpgrade on a copy of the Odoo 17 dump.
3. Fix any migration issues module by module.
4. Only after OpenUpgrade succeeds, test that migrated DB in the normal addon-enabled Odoo 18 stack.
5. Once local testing is stable, repeat the same procedure on the VM.

## References

1. OpenUpgrade docs: https://oca.github.io/OpenUpgrade/
2. OpenUpgrade run guide: https://oca.github.io/OpenUpgrade/040_run_migration.html
3. Odoo 18 upgrade docs: https://www.odoo.com/documentation/18.0/administration/upgrade.html
