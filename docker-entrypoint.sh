#!/bin/sh
set -e

if [ -d "/docker-entrypoint.d" ]; then
    for f in /docker-entrypoint.d/*.sh; do
        if [ -f "$f" ]; then
            . "$f"
        fi
    done
fi

nginx -t

exec "$@"
