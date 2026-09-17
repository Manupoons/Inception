#!/bin/sh
set -e

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mariadb-install-db --user=mysql \
						--datadir=/var/lib/mysql \
						--auth-root-authentication-method=normal

	mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &
	pid="$!"

	i=0
	until mariadb-admin ping --silent 2>/dev/null; do
		i=$((i + 1))
		if [ "$i" -ge 30 ]; then
			echo "entrypoint: mariadbd did non start in time" >&2
			exit 1
		fi
		sleep 1
	done

	mariadb -u root << EOF
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
		CREATE USER IF NOT EXISTS '${MYSQL_ADMIN_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_ADMIN_USER}'@'%';
		FLUSH PRIVILEGES;
EOF

	mariadb-admin --user=root --password="${MYSQL_ROOT_PASSWORD}" shutdown
	wait "$pid"
fi

exec mariadbd