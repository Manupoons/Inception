#!/bin/ash
# stop if setup fails
set -e

# Accept all incoming connections instead of only 127.0.0.1
if [ ! -e /etc/.setup ]; then
	cat <<-DONE >> /etc/my.cnf.d/mariadb-server.cnf
		[mysqld]
		bind-address=0.0.0.0
		skip-networking=0
		DONE
	touch /etc/.setup
fi

# Create and configure the database
if [ ! -e /var/lib/mysql/.setup ]; then

	mysql_install_db --datadir=/var/lib/mysql \
		--skip-test-db --user=mysql --group=mysql \
		--auth-root-authentication-method=socket >/dev/null 2>&1

	# Start a temporary server to run setup queries
	mariadbd-safe --skip-networking=0 --bind-address=127.0.0.1 >/dev/null 2>&1 &

	# Wait until MariaDB is ready
	until mariadb-admin ping -u root --silent >/dev/null 2>&1; do
		echo "Waiting for MariaDB to start..."
		sleep 1
	done

	# Create database, user and set root password
	mariadb --protocol=socket -u root <<-DONE
		CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
		FLUSH PRIVILEGES;
		DONE

	# Shut down the temporary server
	mariadb-admin -u root -p"${MARIADB_ROOT_PASSWORD}" shutdown

	touch /var/lib/mysql/.setup
fi

exec "$@"