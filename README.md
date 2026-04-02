# Docker + nginx-proxy + Let's Encrypt

Automated reverse proxy with free SSL certificates via Let's Encrypt.

[Russian version / Русская версия](README.ru.md)

## Overview

This project provides a Docker-based nginx reverse proxy with automatic SSL certificate provisioning and renewal using Let's Encrypt. It is designed for deploying microservice architectures on a fresh server or alongside an existing Apache installation.

**Do not install on a server that already uses ports 80/443** -- they will conflict.

## Requirements

- Docker
- Docker Compose

## Quick Start

### 1. Clone the repository

```bash
git clone git@github.com:ishapkin/nginx-proxy-letsencrypt.git /srv/proxy
cd /srv/proxy
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and set your values:

| Variable | Description | Default |
|----------|-------------|---------|
| `DEFAULT_EMAIL` | Email for Let's Encrypt notifications | `admin@example.com` |
| `NGINX_PROXY_CONTAINER` | Name of the proxy container | `nginx-proxy` |
| `CLIENT_MAX_BODY_SIZE` | Max upload size (set in `proxy_settings.conf`) | `100M` |

### 3. Create the Docker network

```bash
docker network create nginx-proxy
```

### 4. Start the proxy

```bash
docker-compose up -d
```

## Adding Backend Services

To proxy a service, add it to the `nginx-proxy` network and set the required environment variables.

Example `docker-compose.yml` for a backend service:

```yaml
services:
  webserver:
    image: nginx:alpine
    container_name: example-webserver
    expose:
      - 80
      - 443
    restart: always
    environment:
      VIRTUAL_HOST: example.com
      LETSENCRYPT_HOST: example.com
      LETSENCRYPT_EMAIL: admin@example.com
    networks:
      - nginx-proxy

networks:
  nginx-proxy:
    external: true
    name: nginx-proxy
```

> Use `expose` instead of `ports` -- the proxy handles external traffic.

## WWW Redirect

To redirect `www.example.com` to `example.com`, create the file `vhost.d/www.example.com`:

```nginx
if ($request_uri !~ "^/.well-known/acme-challenge") {
    return 301 https://example.com;
}
```

Then restart:

```bash
docker-compose restart
```

## Basic Authentication

To enable HTTP Basic Auth for a domain:

```bash
htpasswd -c htpasswd/example.com username
```

The credentials file is automatically mounted into nginx.

## Project Structure

```
.
├── docker-compose.yml      # Proxy and ACME companion services
├── .env                    # Environment variables (not tracked by git)
├── .env.example            # Example environment file
├── proxy_settings.conf     # Global nginx settings (e.g. max body size)
├── certs/                  # SSL certificates (auto-generated)
├── html/                   # ACME challenge files
├── vhost.d/                # Per-domain nginx configs
│   └── default             # ACME challenge endpoint
└── htpasswd/               # Basic auth credentials per domain
```

## Architecture

```
Internet (ports 80, 443)
        |
   nginx-proxy (reverse proxy + SSL termination)
        |
   docker network: nginx-proxy
        |
   backend containers (discovered via VIRTUAL_HOST)
```

The proxy uses the Docker socket to automatically detect containers with `VIRTUAL_HOST` set and generates nginx configuration on the fly.
