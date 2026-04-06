# Custom Nginx Docker Image

Multi-arch (amd64/arm64) Alpine-based nginx image compiled from source with WordPress-optimized third-party modules. Published to [ghcr.io](https://ghcr.io).

## Features

- **nginx 1.28.3** compiled from source with static modules
- **Multi-arch**: linux/amd64, linux/arm64
- **Tiny runtime**: ~14 MB (vs 62 MB for `nginx:alpine`)
- **Cloudflare zlib** on amd64 for faster compression
- **Dynamic TLS records** patch for optimized TLS throughput
- **HTTP/3 (QUIC)** support built-in
- **Health check** included via `wget`
- Minimal stub config — bring your own via volume mounts

## Included Modules

| Module | Description |
|--------|-------------|
| [ngx_brotli](https://github.com/google/ngx_brotli) | Brotli compression |
| [ngx_cache_purge](https://github.com/nginx-modules/ngx_cache_purge) | FastCGI/SCGI/uwsgi cache purge |
| [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module) | Set/clear HTTP headers |
| [echo-nginx-module](https://github.com/openresty/echo-nginx-module) | Shell-style utilities in config |
| [ngx_devel_kit](https://github.com/simpl/ngx_devel_kit) | Nginx Development Kit |
| [set-misc-nginx-module](https://github.com/openresty/set-misc-nginx-module) | Additional set_* directives |
| [memc-nginx-module](https://github.com/openresty/memc-nginx-module) | Memcached upstream module |
| [redis2-nginx-module](https://github.com/openresty/redis2-nginx-module) | Redis 2.0 upstream module |
| [srcache-nginx-module](https://github.com/openresty/srcache-nginx-module) | Transparent subrequest caching |
| [ngx_http_redis](https://github.com/centminmod/ngx_http_redis) | Simple Redis handler |
| [ngx_http_substitutions_filter_module](https://github.com/yaoweibin/ngx_http_substitutions_filter_module) | Regular expression response substitution |
| [nginx-module-vts](https://github.com/vozlt/nginx-module-vts) | Virtual host traffic status |
| [ipscrub](https://github.com/masonicboom/ipscrub) | IP address anonymization for logs |

## Quick Start

```sh
docker pull ghcr.io/aryaprakasa/nginx:latest
docker run -d -p 80:80 -p 443:443 -p 443:443/udp ghcr.io/aryaprakasa/nginx:latest
```

### With custom config

```sh
docker run -d \
  -p 80:80 -p 443:443 -p 443:443/udp \
  -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /path/to/conf.d:/etc/nginx/conf.d:ro \
  -v /path/to/html:/usr/share/nginx/html:ro \
  ghcr.io/aryaprakasa/nginx:latest
```

### Docker Compose

```yaml
services:
  nginx:
    image: ghcr.io/aryaprakasa/nginx:latest
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./conf.d:/etc/nginx/conf.d:ro
      - ./html:/usr/share/nginx/html:ro
    restart: unless-stopped

  php:
    image: php:fpm-alpine
    volumes:
      - ./html:/usr/share/nginx/html:ro
    restart: unless-stopped
```

## Tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest build from main |
| `1.28.3` | Pinned version |
| `1.28` | Minor version (latest patch) |

## Build Locally

```sh
docker build -t custom-nginx .

# For a specific platform
docker build --platform linux/amd64 -t custom-nginx .
```

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS (TLS) |
| 443 | UDP | HTTP/3 (QUIC) |

## License

[MIT](LICENSE)
