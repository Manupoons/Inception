FROM alpine:3.23.4

RUN apk update && apk add --no-cache \
		php83 \
		php83-fpm \
		php83-mysqli \
		php83-json \
		php83-curl \
		php83-dom \
		php83-mbstring \
		php83-openssl \
		php83-xml \
		php83-tokenizer \
		php83-phar \
		php83-session \
		php83-zip \
		mariadb-client \
		netcat-openbsd \
		wget \
	&& rm -rf /var/cache/apk/* \
	&& ln -s /usr/bin/php83 /usr/bin/php

RUN wget -O /usr/local/bin/wp https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar \
	&& chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/wordpress && chown -R nobody:nobody /var/www/wordpress \
	&& echo "memory_limit = 512M" > /etc/php83/conf.d/99-custom.ini

COPY conf/wordpress.conf /etc/php83/php-fpm.d/www.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]