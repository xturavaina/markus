
# =========================
# Stage 1: build (compilar extensions)
# =========================


FROM php:8.3-cli-bookworm AS build
LABEL maintainer="xtura vaina"


# Libs de compilació per a extensions PHP (inclou $PHPIZE_DEPS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    $PHPIZE_DEPS \
    git \
    unzip \
    libbz2-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libonig-dev \
    libpng-dev \
    libsodium-dev \
    libssh2-1-dev \
    libwebp-dev \
    libxslt1-dev \
    libzip-dev \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

# Extensions core (compilades)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install -j"$(nproc)" \
    bcmath bz2 calendar exif ftp gd gettext intl mbstring mysqli opcache \
    pcntl pdo_mysql soap sockets sodium sysvmsg sysvsem sysvshm xsl zip

# Extensions PECL
RUN pecl channel-update pecl.php.net \
 && pecl install redis-6.2.0 ssh2-1.4.1 swoole-6.0.2 imagick-3.8.0RC2 \
 && docker-php-ext-enable imagick redis ssh2 \
 && pecl clear-cache && rm -rf /tmp/pear

# Guardem on s’han instal·lat les .so i els .ini
RUN echo "$(php -r 'echo ini_get(\"extension_dir\");')" > /tmp/extdir

# =========================
# Stage 2: runtime (mínim)
# =========================
FROM php:8.3-cli-bookworm

# Paquets només runtime (sense -dev)
RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    cron \
    default-mysql-client \
    gzip \
    libbz2-1.0 \
    libfreetype6 \
    libicu72 \
    libjpeg62-turbo \
    libmagickwand-6.q16-6 \
    libonig5 \
    libpng16-16 \
    libsodium23 \
    libssh2-1 \
    libwebp7 \
    libxslt1.1 \
    libzip4 \
    mailutils \
    msmtp \
    procps \
    rsync \
    zip \
    zlib1g \
  && rm -rf /var/lib/apt/lists/*

# Copiem extensions i configuració des del build
# - Directori d'extensions (.so)
# - Fitxers d'activació a /usr/local/etc/php/conf.d
COPY --from=build /tmp/extdir /tmp/extdir
RUN EXT_DIR="$(cat /tmp/extdir)" \
 && mkdir -p "${EXT_DIR}" \
 && true
COPY --from=build /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=build /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Usuari d’execució
ARG APP_ID=1000
RUN groupadd -g "$APP_ID" app \
  && useradd -g "$APP_ID" -u "$APP_ID" -d /var/www -s /bin/bash app


# Supervisor base
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor
COPY ./conf/supervisord.conf /etc/supervisor/supervisord.conf

# Entrypoint que genera programes per consumer i arrenca supervisord
COPY conf/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# USER app:app
VOLUME /var/www
WORKDIR /var/www/html
ENTRYPOINT ["/entrypoint.sh"]