FROM odoo:18.0

USER root

# Keep third-party addons inside the image so the VM only needs the image plus
# the compose files, instead of the whole repository.
COPY repo-addons/ /mnt/extra-addons/
COPY docker/odoo.conf /etc/odoo/odoo.conf

RUN mkdir -p /mnt/extra-addons /var/lib/odoo/addons/18.0 \
    && chown -R odoo:odoo /mnt/extra-addons /etc/odoo /var/lib/odoo

USER odoo
