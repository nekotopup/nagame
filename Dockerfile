FROM alpine:3.21

# ─── Install PHP + Node ───────────────────────────────────────────────────────
RUN apk add --no-cache \
    nginx \
    php84 php84-fpm \
    php84-bcmath \
    php84-ctype \
    php84-curl \
    php84-dom \
    php84-exif \
    php84-fileinfo \
    php84-gd \
    php84-iconv \
    php84-intl \
    php84-mbstring \
    php84-mysqli \
    php84-opcache \
    php84-openssl \
    php84-pcntl \
    php84-pdo \
    php84-pdo_mysql \
    php84-phar \
    php84-posix \
    php84-session \
    php84-simplexml \
    php84-sockets \
    php84-tokenizer \
    php84-xml \
    php84-xmlreader \
    php84-xmlwriter \
    php84-zip \
    nodejs npm \
    bash curl git unzip

RUN ln -sf /usr/bin/php84 /usr/bin/php \
    && ln -sf /usr/sbin/php-fpm84 /usr/sbin/php-fpm

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ─── PHP dependencies ─────────────────────────────────────────────────────────
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

# ─── Node dependencies ────────────────────────────────────────────────────────
COPY package.json package-lock.json ./
RUN npm ci

# ─── Application code ─────────────────────────────────────────────────────────
COPY . .

# ─── Build assets (wayfinder needs PHP, Vite needs Node) ─────────────────────
RUN cp .env.example .env \
    && php artisan key:generate \
    && php artisan wayfinder:generate --no-interaction \
    && npm run build \
    && php artisan package:discover --ansi \
    && rm .env

# ─── Nginx config (Diselaraskan ke Port 9000 TCP) ───────────────────────────────
RUN mkdir -p /run/nginx && \
    echo 'server { \
        listen 80; \
        root /var/www/html/public; \
        index index.php index.html; \
        location / { try_files $uri $uri/ /index.php?$query_string; } \
        location ~ \.php$ { \
            try_files $uri =404; \
            fastcgi_split_path_info ^(.+\.php)(/.+)$; \
            fastcgi_pass 127.0.0.1:9000; \
            fastcgi_index index.php; \
            include fastcgi_params; \
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
            fastcgi_param PATH_INFO $fastcgi_path_info; \
        } \
    }' > /etc/nginx/http.d/default.conf

# ─── Permissions ─────────────────────────────────────────────────────────────
RUN chown -R nobody:nobody /var/www/html \
    && chown -R nobody:nobody /var/www/html/storage /var/www/html/bootstrap/cache /var/lib/nginx /var/log/nginx /run/nginx \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80

# Kita pastikan PHP-FPM memaksa mendengarkan port 9000 secara global lewat bendera -d
CMD ["sh", "-c", "php artisan optimize && php artisan migrate --force && /usr/sbin/php-fpm84 --nodaemonize --fpm-config /etc/php84/php-fpm.conf -d listen=127.0.0.1:9000 & nginx -g 'daemon off;'"]
