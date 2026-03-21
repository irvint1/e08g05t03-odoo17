# Odoo 18 Migration Checklist

## What changed in this repo
- The Docker image now runs the official `odoo:18.0` image.
- The image bundles `repo-addons` so the VM no longer needs the whole repository.
- The VM compose file now expects a single image tag, by default `odoo-erp:18.0-bundle`.

## Important migration rule
- Do not restore an Odoo 17 database straight into Odoo 18 and expect it to work.
- The database dump used with `odoo.sql.gz` must already be upgraded to Odoo 18.
- Odoo's upgrade documentation says custom modules must also be updated to the target version before the database upgrade is performed.

## What you must update before booting Odoo 18
1. Upgrade the database from Odoo 17 to Odoo 18 using an upgrade path that supports your edition.
2. Replace the current `repo-addons` snapshot with Odoo 18-compatible code.
3. Make sure every installed third-party dependency exists in the image.

## Current addon snapshot status
- `repo-addons` has been upgraded to the OCA Helpdesk `18.0` branch.
- These installed modules were validated on a fresh Odoo 18 database:
  - `helpdesk_mgmt`
  - `helpdesk_mgmt_merge`
  - `helpdesk_mgmt_project`
  - `helpdesk_mgmt_sale`
  - `helpdesk_ticket_related`
  - `helpdesk_type`
- The imported database dump you tested is still an Odoo 17 database, so it still cannot be opened directly by Odoo 18.

## Recommended migration sequence
1. Take a fresh backup of the current Odoo 17 database and filestore.
2. Upgrade or replace every custom and OCA module with its Odoo 18 version.
3. Produce an Odoo 18-compatible database dump.
4. Build the image from this repository.
5. Package the VM bundle with `scripts/build-vm-bundle.ps1`.
6. Copy the generated zip to the VM, unzip it, review `.env.vm`, and run `scripts/start-odoo-vm.sh`.
