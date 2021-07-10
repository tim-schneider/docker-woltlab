FROM php:8-fpm

# Install NGINX
RUN apt-get update && apt-get install -y nginx

# Install Dependencies
RUN apt-get install -y \
        libpng-dev \
        libwebp-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libjpeg-dev \
        libpq-dev \
        libpq5 \
        libjpeg62-turbo \
        libfreetype6 \
        git \
        wget \
        unzip \
        libmagickwand-dev \
        cron

# Install PHP Extensions
RUN docker-php-ext-install pdo_mysql mysqli && \
    docker-php-ext-install pdo_pgsql && \
    docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg && \
    docker-php-ext-install gd && \
    docker-php-ext-install exif && \
    pecl install imagick && \
    docker-php-ext-enable imagick && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl && \
    pecl install -o -f redis && \
    rm -rf /tmp/pear && \
    docker-php-ext-enable redis
    

# Include Woltlab Setup
RUN wget -O /tmp/woltlab.zip https://assets.woltlab.com/release/woltlab-suite-5.3.10.zip && \
    unzip /tmp/woltlab.zip -d /tmp/woltlab && \
    mkdir -p /var/www/woltlab && \
    mkdir -p /opt/woltlab && \
    mv /tmp/woltlab/upload/* /opt/woltlab

# Setup crontab
COPY cron.php /opt/woltlab/cron.php
COPY crontab /etc/cron.d/woltlab-cron
RUN chmod 0644 /etc/cron.d/woltlab-cron
RUN crontab /etc/cron.d/woltlab-cron

COPY nginx-site.conf /etc/nginx/sites-enabled/default
COPY entrypoint.sh /etc/entrypoint.sh

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/conf.d/php.ini
RUN sed -i -e 's/memory_limit = 128M/memory_limit = 512M/g' /usr/local/etc/php/conf.d/php.ini

EXPOSE 80
WORKDIR /var/www/woltlab
ENTRYPOINT ["sh", "/etc/entrypoint.sh"]
