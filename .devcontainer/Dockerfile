FROM ubuntu:24.04

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/

RUN uv tool install zensical --python-preference only-managed

# Add uv tool installed binaries to PATH.
ENV PATH="/root/.local/bin:$PATH"
