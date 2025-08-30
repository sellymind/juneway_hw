FROM alpine:3.22.1

RUN apk update && \
    apk add --no-cache nginx && \
    mkdir -p /run/nginx && \
    mkdir -p /var/www/html && \
    mkdir -p /var/log/nginx && \
    
