# Developer Documentation

This document explains how to set up, build, and work on the Inception project from a
developer's point of view.

## 1. Prerequisites

- A virtual machine (Alpine or Debian) with:
  - Docker Engine
  - Docker Compose (v2, invoked as `docker compose`)
  - `make`
- Network access from the VM (required at build time to install packages via `apk` and
  to download WP-CLI).

## 2. Repository layout

```
Inception/
├── Makefile
├── secrets/
│   ├── credentials.txt        # WordPress admin password
│   ├── db_password.txt        # MariaDB application-user password
│   └── db_root_password.txt   # MariaDB root password
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/mariadb.conf
        │   └── tools/entrypoint.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/entrypoint.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/wordpress.conf
            └── tools/entrypoint.sh
```

`secrets/` and `srcs/.env` are not committed to Git — they must exist locally on the
VM before the project can be built.

## 3. Setting up the environment from scratch

### 3.1 Secrets

Create three plaintext files under `secrets/` at the project root, each containing a
single value with no trailing newline issues:

```
secrets/db_root_password.txt   # MariaDB root password
secrets/db_password.txt        # Password shared by the WordPress DB user and the extra WP author user
secrets/credentials.txt        # WordPress admin account password
```

These are mounted read-only inside containers at `/run/secrets/<name>` by Docker
Compose's `secrets:` section — they are never passed as environment variables and
never appear in `docker-compose.yml` itself.

### 3.2 `.env`

Create `srcs/.env` with the non-sensitive configuration referenced by the entrypoint
scripts and Dockerfiles:

```env
DOMAIN_NAME=mamaratr.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=<wordpress db user>
MYSQL_ADMIN_USER=<second db admin-level user — used only inside mariadb entrypoint>

WP_ADMIN_USER=<wordpress admin username — must NOT contain "admin"/"administrator">
WP_ADMIN_EMAIL=<wordpress admin email>

WP_USER=<second, non-admin wordpress user>
WP_USER_EMAIL=<second user's email>
```

Note: `MYSQL_ADMIN_USER` is created in the `mariadb` entrypoint but is a *database*
user (SQL grant), separate and unrelated to `WP_ADMIN_USER`, which is the WordPress
application-level administrator account created via `wp core install`.

### 3.3 Domain resolution

Point `mamaratr.42.fr` at the VM's own local IP inside the VM's `/etc/hosts` (and on
the host machine's `/etc/hosts` if you want to browse to it from outside the VM):

```
<VM local IP>   mamaratr.42.fr
```

## 4. Build and launch

Everything is driven through the root `Makefile`, which wraps `docker compose`:

```sh
make          # = make up: creates host data dirs, builds images, starts containers (detached)
make down     # stops and removes containers (images/volumes untouched)
make clean    # down + removes built images
make fclean   # clean + removes named volumes + wipes /home/mamaratr/data/{mariadb,wordpress}
make re       # fclean + all (full rebuild from scratch)
```

`make up` creates `/home/mamaratr/data/mariadb` and `/home/mamaratr/data/wordpress` on
the host before calling `docker compose ... up -d --build`, since those are the bind
targets for the two named volumes and must exist beforehand.

Build order is handled by `depends_on` in `docker-compose.yml`: `mariadb` → `wordpress`
→ `nginx`. Note `depends_on` only waits for the container to *start*, not for the
service inside it to be ready — that's why both the `wordpress` and readiness checks
inside `entrypoint.sh` poll `mariadb-admin ping` in a retry loop before proceeding.

## 5. Useful commands for managing containers and volumes

```sh
docker compose -f srcs/docker-compose.yml ps          # container status
docker compose -f srcs/docker-compose.yml logs -f nginx     # follow logs for one service
docker compose -f srcs/docker-compose.yml exec mariadb sh   # shell into a running container
docker volume ls                                       # list Docker volumes
docker volume inspect srcs_mariadb_data                # confirm bind path on host
docker network inspect srcs_inception                  # confirm containers on the network
```

To rebuild a single service after editing its Dockerfile:

```sh
docker compose -f srcs/docker-compose.yml up -d --build mariadb
```

## 6. Where project data lives and how it persists

Both `mariadb_data` and `wordpress_data` are Docker named volumes declared with the
`local` driver and `type: none, o: bind` options, pinning their actual storage to:

- `/home/mamaratr/data/mariadb` → mounted at `/var/lib/mysql` in the `mariadb`
  container
- `/home/mamaratr/data/wordpress` → mounted at `/var/www/wordpress` in both the
  `wordpress` and `nginx` containers (nginx needs read access to serve WordPress's
  static files and pass PHP requests through)

Because the data lives on the host filesystem (not inside the container's writable
layer), it survives `docker compose down` and container rebuilds. It is only removed
by `make fclean` (`docker compose down -v` + explicit `rm -rf` of the data
directories) or `make re`.

The `mariadb` and `wordpress` entrypoint scripts each check for a marker of prior
initialization (`/var/lib/mysql/mysql` directory, `wp-config.php` file respectively)
before running first-boot setup, so restarting the containers on top of existing data
does not re-run installation.