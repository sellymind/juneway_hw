FROM debian:stable-slim AS builder

RUN apt update && \
    apt install -y \
    wget \
    build-essential \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    libgd-dev \
    && rm -rf /var/lib/apt/lists/*

ARG NGINX_VER=1.29.0
RUN wget -q http://nginx.org/download/nginx-${NGINX_VER}.tar.gz && \
    tar -xf nginx-${NGINX_VER}.tar.gz && \
    rm nginx-${NGINX_VER}.tar.gz

WORKDIR /nginx-${NGINX_VER}
RUN ./configure --prefix=/usr/local/nginx  \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --with-pcre \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_stub_status_module \
    --with-http_image_filter_module=dynamic \
    --modules-path=/etc/nginx/modules \
    && make && make install
RUN useradd -r -s /bin/false nginx && \
    mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx

FROM debian:stable-slim

RUN apt update && \
    apt install -y \
    libpcre2-posix3 \
    libpcre2-32-0 \
    zlib1g \
    openssl \
    libgd3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /usr/local/nginx /usr/local/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /var/cache/nginx /var/cache/nginx

RUN useradd -r -s /bin/false nginx && \
    mkdir -p /var/log/nginx && \
    mkdir -p /var/run && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx

RUN mkdir -p /etc/nginx/conf.d && \
    mkdir -p /usr/share/nginx/html

COPY --from=builder /nginx-*/conf/nginx.conf /etc/nginx/nginx.conf

RUN echo "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Nginx Custom Build</title></head><body><h1>Nginx успешно собран из исходников!</h1></body></html>" > /usr/local/nginx/html/index.html

EXPOSE 80

VOLUME ["/etc/nginx/conf.d", "/usr/share/nginx/html", "/var/log/nginx"]

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
