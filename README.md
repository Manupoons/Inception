*This project has been created as part of the 42 curriculum by mamaratr.*

# Inception

## Description

Inception is a system administration project that builds a small, self-contained web
infrastructure entirely with Docker and Docker Compose, run inside a dedicated virtual
machine. It reproduces the classic LEMP-style stack — but split across isolated
containers instead of one shared server — to practice container orchestration,
networking, secret management, and Dockerfile writing from scratch.

The stack is made of three custom-built services, each with its own Dockerfile (no
pre-built application images are pulled from Docker Hub):

- **mariadb** — a MariaDB server (Alpine 3.23.4 base) that stores the WordPress
  database, initialized on first boot with a root user, an application user, and the
  WordPress database itself.
- **wordpress** — PHP-FPM 8.3 running WordPress, installed and configured via WP-CLI
  on first boot (no bundled web server — PHP-FPM only, served over FastCGI).
- **nginx** — the only public entrypoint into the infrastructure, terminating TLS
  (TLSv1.2/TLSv1.3, self-signed certificate) on port 443 and forwarding PHP requests to
  the WordPress container.

Containers communicate over a single dedicated bridge network (`inception`), and two
Docker named volumes persist state: one for the MariaDB data directory, one for the
WordPress files, both physically backed by `/home/mamaratr/data/` on the VM's host
filesystem. All services are set to `restart: on-failure`.

### Design choices and comparisons

**Virtual Machine vs Docker** — The whole project runs inside a VM (as required by the
subject) rather than directly on bare metal, giving an isolated, disposable OS layer
that can be wiped and rebuilt without affecting the host. Docker is used *inside* that
VM to further isolate each service (mariadb, wordpress, nginx) into its own
lightweight, reproducible container, rather than installing all three services
directly on the VM's OS. The VM provides hardware-level isolation and a clean base OS;
Docker provides fast, declarative, per-service isolation on top of it — the two solve
different problems and are used together rather than as alternatives to one another.

**Secrets vs Environment Variables** — Non-sensitive configuration (domain name,
database name, usernames, emails) is stored in a `.env` file and injected as regular
environment variables, since this data isn't confidential and needs to be readable by
`docker-compose.yml` itself. Actual passwords (MariaDB root password, MariaDB user
password, WordPress admin password) are stored as Docker **secrets** instead — files
under `secrets/` that Docker mounts read-only at `/run/secrets/<name>` inside each
container's filesystem (never as environment variables, and never baked into an
image), and are excluded from the Git repository via `.gitignore`. This means
passwords are never visible in `docker inspect`, `docker-compose.yml`, or the image
layers — only in the container's ephemeral runtime filesystem.

**Docker Network vs Host Network** — Containers talk to each other over a dedicated
user-defined bridge network (`inception`), which gives them DNS-based service
discovery (e.g. wordpress reaches the database simply via the hostname `mariadb`) and
keeps their ports private to that network by default. `network: host` (which would
share the VM's own network namespace directly) is not used, since that would remove
the isolation between containers and expose every container port on the host directly
— it's also explicitly forbidden by the subject.

**Docker Volumes vs Bind Mounts** — The two persistent datasets (MariaDB data,
WordPress files) use Docker **named volumes** rather than plain bind mounts. Docker
manages the volume's lifecycle and permissions consistently, while the `local` driver
with `type: none, o: bind` options is used to pin the volume's physical storage to a
specific host path (`/home/mamaratr/data/mariadb` and `/home/mamaratr/data/wordpress`)
— satisfying both the "must be named volumes" requirement and the "must live under
`/home/login/data`" requirement at the same time.

## Instructions

Prerequisites: a running VM with Docker and Docker Compose installed, and a `.env`
file plus the `secrets/` folder populated (see `DEV_DOC.md` for exact steps).

```sh
make        # builds images and starts all containers (equivalent to `make up`)
make down   # stops containers
make clean  # stops containers and removes built images
make fclean # full reset: removes images, volumes, and wipes local data directories
make re     # fclean + all
```

Once running, the site is reachable at `https://mamaratr.42.fr` (see `USER_DOC.md` for
how to point that domain at the VM). Detailed day-to-day usage is in `USER_DOC.md`;
environment setup and internals are in `DEV_DOC.md`.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [MariaDB Docker best-practice notes / Alpine `mariadb-install-db`](https://mariadb.com/kb/en/)
- [WP-CLI documentation](https://wp-cli.org/)
- [Alpine Linux packages (`php83`, `nginx`, `mariadb`)](https://pkgs.alpinelinux.org/)
- [About PID 1 and container init behaviour](https://github.com/Yelp/dumb-init#why-do-i-need-an-init-system)

**AI usage:** AI assistance (Claude) was used during this project for:
- Assistance with Docker Compose configuration, Nginx setup, and troubleshooting container issues.
- Reviewing Dockerfiles and entrypoint scripts for best practices.
- Drafting the structure and comparison sections of this README, `DEV_DOC.md`, and
  `USER_DOC.md`, based on the actual `Makefile`, `docker-compose.yml`, `Dockerfile`s,
  and entrypoint scripts written for this project.