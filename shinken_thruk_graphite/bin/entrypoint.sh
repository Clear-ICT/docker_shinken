#!/bin/sh

mkdir -p /var/lib/graphite/storage
graphite-manage syncdb --noinput
graphite-manage createsuperuser --username=admin --email=root@localhost --noinput
chown -R _graphite:_graphite /var/lib/graphite/*

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n

