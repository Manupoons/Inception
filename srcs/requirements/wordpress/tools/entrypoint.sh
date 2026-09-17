#!/bin/sh
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials)

i=0
until mariadb-admin ping -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
		i=$((i + 1))
		if [ "$i" -ge 30 ]; then
			echo "entrypoint: mariadb did not become ready in time" >&2
			exit 1
		fi
		echo "Waiting for MariaDB..."
	sleep 2
done

if [ ! -f "/var/www/wordpress/wp-config.php" ]; then
	echo "Downloading WordPress..."
	wp core download --path=/var/www/wordpress --allow-root

	echo "Creating wp-config.php..."
	cat << EOF > /var/www/wordpress/wp-config.php

<?php
define( 'DB_NAME', '${MYSQL_DATABASE}' );
define( 'DB_USER', '${MYSQL_USER}' );
define( 'DB_PASSWORD', '${MYSQL_PASSWORD}' );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

define( 'WP_HOME', 'https://' .\$_SERVER['HTTP_HOST'] );
define( 'WP_SITEURL', 'https://' .\$_SERVER['HTTP_HOST'] );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false);

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF

	echo "Installing WordPress..."
	wp core install \
		--path=/var/www/wordpress \
		--url="https://${DOMAIN_NAME}" \
		--title="Inception" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--allow-root

	echo "Creating extra user..."
	wp user create \
		"${WP_USER}" \
		"${WP_USER_EMAIL}" \
		--role=author \
		--user_pass="${MYSQL_PASSWORD}" \
		--path=/var/www/wordpress \
		--allow-root

	chown -R nobody:nobody /var/www/wordpress
fi

echo "Starting PHP-FPM..."
exec php-fpm83 -F