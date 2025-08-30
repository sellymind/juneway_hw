FROM debian:stable-slim as builder

RUN apk update && \
    apk install -y \
    wget \
    build-essential \
    libpcre3-dev \
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
