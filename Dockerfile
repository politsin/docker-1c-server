FROM docker-php

ENV PLATFORM_VERSION=83
ENV SERVER_VERSION=8.3.9-2170

ENV GOSU_VERSION 1.7

RUN apt-get -qq update && \
    apt-get install -y apache2 imagemagick && \
    apt-get install -y --no-install-recommends ca-certificates \
                                               locales \
                                               fontconfig \
                                               xfonts-utils \
                                               cabextract && \
    wget --quiet --output-document /tmp/ttf-mscorefonts-installer_3.6_all.deb http://ftp.us.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb && \
    dpkg --install /tmp/ttf-mscorefonts-installer_3.6_all.deb && \
    rm /tmp/ttf-mscorefonts-installer_3.6_all.deb && \
    wget --quiet --output-document /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true

RUN localedef --inputfile ru_RU --force --charmap UTF-8 --alias-file /usr/share/locale/locale.alias ru_RU.UTF-8
ENV LANG ru_RU.utf8

ADD deb/*.deb /tmp/

RUN dpkg --install /tmp/1c-enterprise$PLATFORM_VERSION-common_${SERVER_VERSION}_amd64.deb && \
    dpkg --install /tmp/1c-enterprise$PLATFORM_VERSION-server_${SERVER_VERSION}_amd64.deb && \
    dpkg --install /tmp/1c-enterprise$PLATFORM_VERSION-ws_${SERVER_VERSION}_amd64.deb && \
    rm /tmp/*.deb && \
    mkdir --parent /var/log/1C /home/usr1cv8/.1cv8/1C/1cv8/conf && \
    chown --recursive usr1cv8:grp1cv8 /var/log/1C /home/usr1cv8

RUN mkdir -p /home/usr1cv8/.1cv8/db && \
	touch /etc/apache2/conf-available/db.conf && \
	/opt/1C/v8.3/x86_64/webinst -apache24 -wsdir db -dir '/home/usr1cv8/.1cv8/db' -connstr 'Srvr="localhost";Ref="db";' -confPath /etc/apache2/conf-available/db.conf && \
	a2enconf db

COPY config/logcfg.xml /home/usr1cv8/.1cv8/1C/1cv8/conf
COPY config/supervisor/supervisord.conf /etc/supervisord.conf

EXPOSE 22 1540-1541 1560-1591

ENTRYPOINT ["/start.sh"]
