# P4PER

[![publish](https://github.com/p4lang/p4per/actions/workflows/publish.yml/badge.svg)](https://github.com/p4lang/p4per/actions/workflows/publish.yml)

The repository for P4 Project Enhancement Requests (P4PERs).

## Read P4PERs

Visit https://p4lang.github.io/p4per/.

## Build P4PERs locally

### Prerequisites

#### With Docker (recommended)

This is recommended because you get exactly the same environment used for CI.

- Docker runtime (one of):
  - [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  - [OrbStack](https://orbstack.dev/)
  - [Colima](https://colima.run/)
- [Dev Container CLI](https://github.com/devcontainers/cli)

#### Without Docker

- [Zensical](https://zensical.org/docs/get-started/)

### Commands

`./dev.sh` runs commands inside the dev container. Without Docker, omit `./dev.sh` and run the commands directly.

Preview the site locally with live reload:

```sh
./dev.sh zensical serve --dev-addr 0.0.0.0:8000
```

Build the site:

```sh
./dev.sh zensical build --clean
```
