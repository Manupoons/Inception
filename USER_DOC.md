# User Documentation

This document explains, from an end user / administrator point of view, how to run and
use the Inception stack — no development knowledge required.

## 1. What the stack provides

Three services work together to serve a WordPress website over HTTPS:

- **nginx** — the only entry point; handles HTTPS (TLSv1.2/TLSv1.3) on port 443 and is
  the only service reachable from outside the Docker network.
- **wordpress** — runs the WordPress site itself (via PHP-FPM); not directly reachable
  from outside — nginx forwards requests to it internally.
- **mariadb** — stores the WordPress database (posts, users, settings); not directly
  reachable from outside either.

## 2. Starting and stopping the project

From the project root, on the VM:

```sh
make        # start everything (builds images the first time)
make down   # stop everything
```

To wipe all data and start completely fresh:

```sh
make fclean
make
```

## 3. Accessing the website and the admin panel

Make sure `mamaratr.42.fr` resolves to the VM's IP address (this only needs to be set
up once — see `DEV_DOC.md` if it isn't working).

- **Website:** `https://mamaratr.42.fr`
- **Admin panel:** `https://mamaratr.42.fr/wp-admin`

Since the certificate is self-signed (as required by the subject), your browser will
show a security warning on first visit — this is expected; proceed past it.

Log in to the admin panel with the WordPress administrator account (see below for
where to find its username and password).

## 4. Locating and managing credentials

- **Database passwords and the WordPress admin password** are stored as plaintext
  files in the `secrets/` folder at the project root: `db_root_password.txt`,
  `db_password.txt`, and `credentials.txt`. These files are private to the VM and are
  never committed to Git.
- **Non-sensitive settings** (the WordPress admin username, the domain name, database
  name, etc.) are in `srcs/.env`.
- There are two WordPress user accounts by design: one **administrator** account (full
  access) and one regular **author** account. Both are created automatically the first
  time the stack starts.

If you ever need to change a password, edit the relevant file in `secrets/`, then
rebuild the affected container so it picks up the new value (existing WordPress/DB
data is unaffected, since the entrypoint scripts only set up accounts once, on first
boot against empty data).

## 5. Checking that services are running correctly

```sh
docker compose -f srcs/docker-compose.yml ps
```

All three services (`mariadb`, `wordpress`, `nginx`) should show a status of `Up`. If
one shows `Restarting`, check its logs:

```sh
docker compose -f srcs/docker-compose.yml logs <service-name>
```

You can also confirm the site itself is responding:

```sh
curl -kI https://mamaratr.42.fr
```

A response starting with `HTTP/1.1 200 OK` (or a redirect) means nginx and the
underlying WordPress/database chain are all working correctly. The `-k` flag is needed
because of the self-signed certificate.