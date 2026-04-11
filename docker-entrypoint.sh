#!/bin/sh
# shellcheck disable=SC2034,SC1091
set -e

ME=$(basename "$0")

if [ -d "/docker-entrypoint.d" ]; then
    for f in /docker-entrypoint.d/*.sh; do
        if [ -f "$f" ]; then
            . "$f"
        fi
    done
fi

for tpl in /etc/nginx/templates/*.template; do
    if [ -f "$tpl" ]; then
        out="/etc/nginx/conf.d/$(basename "$tpl" .template)"
        envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < "$tpl" > "$out"
    fi
done

nginx -t

exec "$@"
