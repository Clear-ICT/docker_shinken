# Shinken Docker installation using pip (latest)
FROM        ubuntu:16.04
MAINTAINER  Michael Telahun

# Add the Syleam monitoring tools repository to apt
RUN         DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::ForceIPv4=true update && apt-get -o Acquire::ForceIPv4=true install -y wget && \
                sh -c "echo 'deb http://download.opensuse.org/repositories/home:/sfl-monitoring:/monitoring-tools/xUbuntu_14.04/ ./' > /etc/apt/sources.list.d/monitoring-tools.list" && \
                cd /tmp && \
                wget http://download.opensuse.org/repositories/home:/sfl-monitoring:/monitoring-tools/xUbuntu_14.04/Release.key && \
                apt-key add - < Release.key && \
                rm Release.key

# Install Shinken, Nagios plugins, apache2 and supervisord
RUN         apt-get -o Acquire::ForceIPv4=true update && apt-get -o Acquire::ForceIPv4=true install -y python-pip \
                python-pycurl \
                python-cherrypy3 \
                nagios-plugins \
                libsys-statistics-linux-perl \
                apache2 \
                apache2-bin \
                libapache2-mod-wsgi \
                supervisor \
                python-dev \
                python-cairo \
                python-crypto \
                libssl-dev \
                inotify-tools \
                ntp           \
                git           \
                mongodb

# Install fping (needed by check_fping nagios plugin)
RUN         apt-get install fping

# Install Syleam plugins
RUN         apt-get -o Acquire::ForceIPv4=true install -y monitoring-plugins-sfl-check-arp-no-change \
                monitoring-plugins-sfl-check-graphite-api \
                monitoring-plugins-sfl-check-http2 \
                monitoring-plugins-sfl-check-linux-bandwidth \
                monitoring-plugins-sfl-check-linux-traffic \
                monitoring-plugins-sfl-check-openerp \
                monitoring-plugins-sfl-check-poller2livestatus \
                monitoring-plugins-sfl-check-postgresql-lag \
                monitoring-plugins-sfl-check-reactionner-health \
                monitoring-plugins-sfl-check-redis \
                monitoring-plugins-sfl-check-samba \
                monitoring-plugins-sfl-check-site-health \
                monitoring-plugins-sfl-check-smtp-success-ratio \
                monitoring-plugins-sfl-check-snmp-interface

# Install additional plugins
RUN         cd /usr/src && git clone https://github.com/Clear-ICT/shinken-plugins.git && \
                cd shinken-plugins && \
                rm -rf .git* README* && \
                cp * /usr/lib/nagios/plugins && \
                cd /usr/src && \
                rm -rf shinken-plugins

# Download and install shinken manually
# For some reason it doesn't install properly with pip
RUN         useradd --create-home shinken && \
                cd /tmp && \
                wget https://github.com/naparuba/shinken/archive/2.4.3.tar.gz && \
                tar -xf 2.4.3.tar.gz && \
                cd shinken-2.4.3 && \
                python setup.py install && \
                cd /tmp && \
                rm -rf 2.4.3.tar.gz shinken-2.4.3 && \
                update-rc.d -f apache2 remove && \
                update-rc.d -f shinken remove

# Install Graphite
RUN         DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install graphite-web graphite-carbon

# Needed for webui2
RUN         pip install pymongo>=3.0.3 requests arrow bottle==0.12.8 passlib
COPY        etc/mongodb.conf /etc/

# Install shinken modules from shinken.io
RUN         chown -R shinken:shinken /etc/shinken/ && \
                su - shinken -c 'shinken --init' && \
                su - shinken -c 'shinken install webui2' && \
                su - shinken -c 'shinken install auth-htpasswd' && \
                su - shinken -c 'shinken install logstore-sqlite' && \
                su - shinken -c 'shinken install booster-nrpe' && \
                su - shinken -c 'shinken install livestatus' && \
                su - shinken -c 'shinken install graphite2' && \
                su - shinken -c 'shinken install ui-graphite2' && \
                su - shinken -c 'shinken install linux-snmp' && \
                su - shinken -c 'shinken install postgresql' && \
                su - shinken -c 'shinken install windows' && \
                su - shinken -c 'shinken install dc' && \
                su - shinken -c 'shinken install ssh'

# Install and configure thruk
RUN         gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7 && \
                gpg --armor --export F8C1CA08A57B9ED7 | apt-key add - && \
                echo "deb http://labs.consol.de/repo/stable/ubuntu xenial main" > /etc/apt/sources.list.d/labs-consol-stable.list && \
                apt-get -o Acquire::ForceIPv4=true update && \
                apt-get -o Acquire::ForceIPv4=true install -y thruk && \
                apt-get clean
ADD         thruk/thruk_local.conf /etc/thruk/thruk_local.conf

# Install check_nrpe plugin
ADD         nrpe-2.15.tar.gz /usr/src/
RUN         cd /usr/src/nrpe-2.15/ && \
                ./configure --with-nagios-user=shinken --with-nagios-group=shinken --with-nrpe-user=shinken --with-nrpe-group=shinken --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu && \
                make all && \
                make install-plugin && \
                mv /usr/local/nagios/libexec/check_nrpe /usr/lib/nagios/plugins/check_nrpe && \
                cd / && \
                rm -rf /usr/src/nrpe-2.15

# Configure apache
ADD         shinken/shinken_apache.conf /etc/apache2/conf.d/shinken_apache.conf
RUN         ln -sf /etc/apache2/mods-available/proxy* /etc/apache2/mods-enabled/
RUN         ln -sf /etc/apache2/mods-available/xml2enc* /etc/apache2/mods-enabled/
RUN         ln -sf /etc/apache2/mods-available/slotmem_shm* /etc/apache2/mods-enabled/

# Configure Shinken modules
RUN         mkdir -p /etc/shinken/custom_configs /usr/local/custom_plugins && \
                ln -sf /etc/shinken/custom_configs/htpasswd.users /etc/shinken/htpasswd.users && \
                rm -f /etc/thruk/htpasswd && \
                ln -sf /etc/shinken/htpasswd.users /etc/thruk/htpasswd
COPY         shinken/shinken.cfg /etc/shinken/
COPY         shinken/broker-master.cfg /etc/shinken/brokers/
COPY         shinken/poller-master.cfg /etc/shinken/pollers/
COPY         shinken/scheduler-master.cfg /etc/shinken/schedulers/
COPY         shinken/webui2.cfg /etc/shinken/modules/
COPY         shinken/livestatus.cfg /etc/shinken/modules/
COPY         shinken/graphite2.cfg /etc/shinken/modules/
COPY         shinken/ui-graphite2.cfg /etc/shinken/modules/
COPY         shinken/snmp-patch.txt /tmp/
RUN          cd /etc/shinken && patch -p2 < /tmp/snmp-patch.txt && \
                 rm /tmp/snmp-patch.txt
RUN          chown -R shinken:shinken /etc/shinken/

# Configure graphite
COPY        graphite/carbon.conf /etc/carbon/
COPY        graphite/storage-schemas.conf /etc/carbon/
COPY        graphite/storage-aggregation.conf /etc/carbon/
COPY        graphite/local_settings.py /etc/graphite/
RUN         cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available && \
                a2dissite 000-default && \
                a2ensite apache2-graphite

# Add shinken config watcher to restart arbiter, when changes happen
ADD         shinken/watch_shinken_config.sh /usr/bin/watch_shinken_config.sh
RUN         chmod 755 /usr/bin/watch_shinken_config.sh

# Copy extra NRPE plugins and fix permissions
ADD         extra_plugins/* /usr/lib/nagios/plugins/
RUN         cd /usr/lib/nagios/plugins/ && \
                chmod a+x * && \
                chmod u+s check_apt restart_service check_ping check_icmp check_fping apt_update

# Additional shinken configuration
RUN         rm /etc/shinken/hosts/localhost.cfg

# configure supervisor
ADD         supervisor/conf.d/* /etc/supervisor/conf.d/

# Expost port 80 (apache2), 7767 (WebUi)
EXPOSE  80
EXPOSE  7767

# Default docker process
COPY        bin/entrypoint.sh /
CMD ["/entrypoint.sh"]
