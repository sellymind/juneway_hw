FROM debian:stable-slim as builder

RUN apt update && \
    apt install -y \
    wget \
    build-essential \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

ARG NGINX_VER=1.29.0
RUN wget -q http://nginx.org/download/nginx-${NGINX_VER}.tar.gz && \
    tar -xf nginx-${NGINX_VER}.tar.gz && \
    rm nginx-${NGINX_VER}.tar.gz

WORKDIR /nginx-${NGINX_VER}
RUN ./configure && make && make install
RUN useradd -r -s /bin/false nginx && \
    mkdir -p /var/cache/nginx && \
    chown -R nginx:nginx /var/cache/nginx

FROM debian:stable-slim

RUN apt update && \
    apt install -y \
    libpcre3 \
    zlib1g \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /usr/local/nginx /usr/local/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /var/cache/nginx /var/cache/nginx

RUN useradd -r -s /bin/false nginx && \
    mkdir -p /var/log/nginx && \
    mkdir -p /var/run &&
    chown -R nginx:nginx /var/log/nginx /var/cache/NGINX_VER

RUN mkdir -p /etc/nginx/conf.d && \
    mkdir -p /usr/share/nginx/html

COPY --from=builder /nginx-*/conf/nginx.conf /etc/nginx/nginx.conf

RUN echo "<!DOCTYPE html><html><head><title>Nginx Custom Build</title></head><body><h1>Nginx успешно собран из исходников!</h1></body></html>" > /usr/share/nginx/html/index.html

EXPOSE 80 443

VOLUME ["/etc/nginx/conf.d", "/usr/share/nginx/html", "/var/log/nginx"]

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
