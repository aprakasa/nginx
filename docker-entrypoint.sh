#!/bin/sh
set -e

nginx -t

exec "$@"
