FROM alpine:3.23.4

RUN apk update && apk add --no-cache \
	mariadb \
	mariadb-client \
	&& rm -rf /var/cache/apk/*

RUN rm /etc/my.cnf.d/mariadb-server.cnf

RUN mkdir -p /run/mysqld \
	&& chown -R mysql:mysql /run/mysqld \
	&& mkdir -p /var/lib/mysql \
	&& chown -R mysql:mysql /var/lib/mysql

COPY conf/mariadb.conf /etc/my.cnf.d/custom.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]