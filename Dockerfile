FROM alpine:3.23 AS builder

ARG NGINX_VERSION=1.28.3
ARG TARGETARCH

RUN apk add --no-cache \
    build-base \
    git \
    curl \
    patch \
    linux-headers \
    openssl-dev \
    pcre2-dev \
    brotli-dev \
    zlib-dev \
    libbsd-dev

WORKDIR /usr/local/src

COPY patches/nginx_dynamic_tls_records.patch /usr/local/src/nginx_dynamic_tls_records.patch

RUN curl -fSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
    && tar xzf nginx.tar.gz \
    && mv nginx-${NGINX_VERSION} nginx

RUN git clone --depth=1 https://github.com/google/ngx_brotli.git \
    && cd ngx_brotli && git submodule update --init && cd .. \
    && git clone --depth=1 https://github.com/nginx-modules/ngx_cache_purge.git \
    && git clone --depth=1 https://github.com/openresty/headers-more-nginx-module.git \
    && git clone --depth=1 https://github.com/openresty/echo-nginx-module.git \
    && git clone --depth=1 https://github.com/simpl/ngx_devel_kit.git \
    && git clone --depth=1 https://github.com/openresty/set-misc-nginx-module.git \
    && git clone --depth=1 https://github.com/openresty/memc-nginx-module.git \
    && git clone --depth=1 https://github.com/openresty/redis2-nginx-module.git \
    && git clone --depth=1 https://github.com/openresty/srcache-nginx-module.git \
    && git clone --depth=1 https://github.com/centminmod/ngx_http_redis.git \
    && git clone --depth=1 https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git \
    && git clone --depth=1 https://github.com/vozlt/nginx-module-vts.git \
    && git clone --depth=1 https://github.com/masonicboom/ipscrub.git ipscrubtmp

RUN cd nginx \
    && patch -p1 < /usr/local/src/nginx_dynamic_tls_records.patch

RUN if [ "$TARGETARCH" = "amd64" ]; then \
        git clone --depth=1 https://github.com/cloudflare/zlib.git -b gcc.amd64 zlib-cf \
        && cd zlib-cf \
        && make -f Makefile.in distclean \
        && ./configure --prefix=/usr/local/zlib-cf \
        && cd ..; \
    fi

RUN cd nginx && \
    if [ "$TARGETARCH" = "amd64" ]; then \
        ZLIB_OPT="--with-zlib=../zlib-cf"; \
    else \
        ZLIB_OPT=""; \
    fi && \
    ./configure \
        --prefix=/usr/share/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/lib/nginx/body \
        --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
        --http-proxy-temp-path=/var/lib/nginx/proxy \
        --http-scgi-temp-path=/var/lib/nginx/scgi \
        --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
        --modules-path=/usr/share/nginx/modules \
        --with-file-aio \
        --with-threads \
        --with-http_v3_module \
        --with-http_v2_module \
        --with-http_ssl_module \
        --with-pcre-jit \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --with-http_auth_request_module \
        --with-http_addition_module \
        --with-http_gzip_static_module \
        --with-http_gunzip_module \
        --with-http_mp4_module \
        --with-http_sub_module \
        --add-module=../ngx_brotli \
        --add-module=../ngx_cache_purge \
        --add-module=../headers-more-nginx-module \
        --add-module=../echo-nginx-module \
        --add-module=../ngx_devel_kit \
        --add-module=../set-misc-nginx-module \
        --add-module=../memc-nginx-module \
        --add-module=../redis2-nginx-module \
        --add-module=../srcache-nginx-module \
        --add-module=../ngx_http_redis \
        --add-module=../ngx_http_substitutions_filter_module \
        --add-module=../nginx-module-vts \
        --add-module=../ipscrubtmp/ipscrub \
        ${ZLIB_OPT} \
        --with-cc-opt='-O2 -fstack-protector-strong -flto -Wno-error=date-time -Wno-cpp' \
        --with-ld-opt='-Wl,--as-needed' \
    && make -j$(nproc) \
    && strip --strip-unneeded objs/nginx

FROM alpine:3.23

RUN apk add --no-cache pcre2 brotli openssl zlib libbsd tzdata \
    && addgroup -S nginx \
    && adduser -S -D -H -G nginx -h /var/cache/nginx -s /sbin/nologin nginx

COPY --from=builder /usr/local/src/nginx/objs/nginx /usr/sbin/nginx
COPY --from=builder /usr/local/src/nginx/conf/mime.types /etc/nginx/mime.types
COPY --from=builder /usr/local/src/nginx/conf/fastcgi_params /etc/nginx/fastcgi_params
COPY --from=builder /usr/local/src/nginx/conf/scgi_params /etc/nginx/scgi_params
COPY --from=builder /usr/local/src/nginx/conf/uwsgi_params /etc/nginx/uwsgi_params

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p /var/lib/nginx/{body,fastcgi,proxy,scgi,uwsgi} \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/cache/nginx \
    && mkdir -p /usr/share/nginx/html \
    && echo '<!DOCTYPE html><html><head><title>Welcome</title></head><body><h1>Welcome to nginx!</h1></body></html>' > /usr/share/nginx/html/index.html \
    && chown -R nginx:nginx /var/cache/nginx /var/log/nginx /var/lib/nginx /usr/share/nginx/html \
    && chmod +x /docker-entrypoint.sh

EXPOSE 80/tcp 443/tcp 443/udp

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost/ || exit 1

STOPSIGNAL SIGQUIT

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
