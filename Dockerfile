# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.22

# set version label
ARG BUILD_DATE
ARG VERSION
ARG KIMAI_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nemchik"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    php84-gd \
    php84-intl \
    php84-ldap \
    php84-pdo_mysql \
    php84-pecl-redis \
    php84-tokenizer \
    php84-xmlreader \
    php84-xsl && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php84/php-fpm.d/www.conf && \
  if ! grep -qxF 'clear_env = no' /etc/php84/php-fpm.d/www.conf; then echo 'clear_env = no' >> /etc/php84/php-fpm.d/www.conf; fi && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php84/php-fpm.conf && \
  echo "**** install kimai ****" && \
  mkdir -p\
    /app/www && \
  if [ -z ${KIMAI_RELEASE+x} ]; then \
    KIMAI_RELEASE=$(curl -sX GET "https://api.github.com/repos/kimai/kimai/releases/latest" \
      | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/kimai.tar.gz -L \
    "https://github.com/kimai/kimai/archive/refs/tags/${KIMAI_RELEASE}.tar.gz" && \
  tar xf \
    /tmp/kimai.tar.gz -C \
    /app/www --strip-components=1 && \
  echo "**** install composer dependencies ****" && \
  COMPOSER_MEMORY_LIMIT=-1 php -d memory_limit=-1 /usr/bin/composer install -d /app/www/ --no-dev --optimize-autoloader --no-interaction && \
  COMPOSER_MEMORY_LIMIT=-1 php -d memory_limit=-1 /usr/bin/composer require -d /app/www/ --update-no-dev laminas/laminas-ldap && \
  /usr/bin/composer clearcache -d /app/www/ && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    $HOME/.cache \
    $HOME/.composer

# add local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config
