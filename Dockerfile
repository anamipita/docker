FROM bitnami/minideb:stretch

RUN apt-get update

RUN apt-get install -y \ 
    apt-transport-https \ 
    lsb-release \ 
    ca-certificates \ 
    wget \ 
    curl \ 
    nano \ 
    dialog \ 
    net-tools \ 
    openssl \
    memcached \
    gnupg

RUN wget https://nginx.org/keys/nginx_signing.key
RUN yes | apt-key add nginx_signing.key
RUN echo "deb https://nginx.org/packages/mainline/debian/ stretch nginx" >>  /etc/apt/sources.list
RUN echo "deb-src https://nginx.org/packages/mainline/debian/ stretch nginx" >>  /etc/apt/sources.list
RUN yes | apt-get remove nginx-common
RUN yes | apt-get update
RUN apt-get install -y nginx

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
RUN apt-get update && apt-get install -y \
    php7.2 \
    php7.2-cli \
    php7.2-fpm \
    php7.2-mysql \
    php7.2-curl \
    php7.2-mbstring \
    php7.2-gettext \
    php7.2-gd \
    php7.2-fileinfo \
    php7.2-json \
    php-mcrypt \
    php7.2-redis \
    php7.2-intl \
    php7.2-xml \
    php7.2-zip \
    php7.2-memcached

ENV TZ=Africa/Nairobi
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN curl -s "https://packagecloud.io/install/repositories/phalcon/stable/script.deb.sh" | bash
RUN apt-get install -y php7.2-phalcon

RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs

COPY deploy/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD deploy/nginx/nginx.conf /etc/nginx/
ADD deploy/nginx/default.conf /etc/nginx/conf.d/
COPY deploy/www.conf /etc/php/7.2/fpm/pool.d/www.conf


ADD . /var/www/html
WORKDIR /var/www/html

RUN mkdir -p app/cache

COPY deploy/.env .env

RUN composer install
RUN npm install
RUN npm run build

RUN chmod -R 777 /var/www/html/app/cache

EXPOSE 80 443

ADD entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod a+x /usr/bin/entrypoint.sh

ENTRYPOINT [ "entrypoint.sh" ]