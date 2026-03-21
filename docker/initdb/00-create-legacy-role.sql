DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'odoo17') THEN
        CREATE ROLE odoo17;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'odoo18') THEN
        CREATE ROLE odoo18;
    END IF;
END
$$;
