# Run Odoo 18 on the VM

## 1) What to send to the VM
Use the bundle created by `scripts/build-vm-bundle.ps1`.

The bundle contains:
- `docker-compose.vm.yml`
- `docker-compose.seed.yml`
- `docker-compose.addons.yml`
- `.env.vm.example`
- `docker/odoo.conf`
- `docker/initdb/00-create-legacy-role.sql`
- `scripts/start-odoo-vm.sh`
- `odoo18-image.tar`
- `odoo.sql.gz` if it exists locally

You no longer need to copy the whole repository to the VM.

## 2) Before you start
- `odoo.sql.gz` must already be an Odoo 18-compatible database dump.
- The bundled `repo-addons` directory must already be updated to Odoo 18-compatible code.
- Review [ODOO18_MIGRATION.md](ODOO18_MIGRATION.md) before deploying.
- The default config now starts Odoo 18 without third-party addons until they are migrated.

## 3) First-time start on the VM
Unzip the bundle on the VM, then run:

```bash
cp .env.vm.example .env.vm
chmod +x scripts/start-odoo-vm.sh
./scripts/start-odoo-vm.sh
```

Open Odoo at `http://<VM_IP>:8069`.

## 4) Check status and logs
```bash
docker compose --env-file .env.vm -f docker-compose.vm.yml ps
docker compose --env-file .env.vm -f docker-compose.vm.yml logs -f db
docker compose --env-file .env.vm -f docker-compose.vm.yml logs -f odoo
```

## 5) Re-import the bootstrap database
If `odoo.sql.gz` is present in the bundle, `scripts/start-odoo-vm.sh` automatically adds `docker-compose.seed.yml`.

`odoo.sql.gz` is imported only when the Postgres volume is empty.

To force a clean re-import:

```bash
docker compose --env-file .env.vm -f docker-compose.vm.yml down -v
./scripts/start-odoo-vm.sh
```

## 6) Default values
- Odoo image: `odoo-erp:18.0-bundle`
- Postgres user: `odoo`
- Postgres password: `odoo`
- Postgres database: `postgres`
- Odoo admin password in `docker/odoo.conf`: `admin`

Change these values before production use.
