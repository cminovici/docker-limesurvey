
FROM php:5.6-apache

MAINTAINER Florian JUDITH <florian.judith.b@gmail.com>


ENV LIMESURVEY_URL=http://download.limesurvey.org/latest-stable-release/limesurvey2.67.3+170728.tar.gz

RUN apt-get update && \
    apt-get install -y \
    crudini \
    git \
    curl \
    wget \
    bzip2 \
    pwgen \
    zip \
    unzip \
    ca-certificates \
    msmtp \
    php-net-smtp

# Install needed php extensions: ldap
RUN apt-get install -y php5-ldap libldap2-dev && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap

# Install needed php extensions: imap
RUN apt-get install -y php5-imap libssl-dev libc-client2007e-dev libkrb5-dev && \
    docker-php-ext-configure imap --with-imap-ssl --with-kerberos && \
    docker-php-ext-install imap

# Install needed php extensions: zip
RUN apt-get -y install zlib1g-dev && \
    docker-php-ext-install zip

# Install needed php extensions: bz2 
RUN apt-get install -y libbz2-dev && \
    docker-php-ext-install bz2

# Install needed php extensions: gd
RUN apt-get install --fix-missing -y libfreetype6-dev libpng12-dev libjpeg62-turbo-dev libzip-dev && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/  && \
    docker-php-ext-install gd

# Install needed php extensions: mysql
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install pdo_mysql

# Install needed php extensions: mcrypt
RUN apt-get -y install re2c libmcrypt-dev && \
    docker-php-ext-install mcrypt

# Install needed php extensions: imagick
RUN apt-get install --fix-missing -y libmagickwand-dev && \
    pecl install imagick && \
    docker-php-ext-enable imagick

# Setup sendmail for php
RUN touch /etc/msmtprc && \
    mkdir -p /var/log/msmtp && \
    chown -R www-data:adm /var/log/msmtp && \
    touch /etc/logrotate.d/msmtp && \
    rm /etc/logrotate.d/msmtp && \
    echo "/var/log/msmtp/*.log {\n rotate 12\n monthly\n compress\n missingok\n notifempty\n }" > /etc/logrotate.d/msmtp && \
    crudini --set /etc/php5/cli/php.ini "mail function" "sendmail_path" "'/usr/bin/msmtp'" && \
    touch /usr/local/etc/php/php.ini && \
    crudini --set /usr/local/etc/php/php.ini "mail function" "sendmail_path" "'/usr/bin/msmtp'"

# Clean up
RUN apt-get clean && \
    rm -r /var/lib/apt/lists/*

# Download and install Limesurvey
RUN cd /var/www/html \
    && curl $LIMESURVEY_URL | tar xvz

# Change owner for security reasons
RUN chown -R www-data:www-data /var/www/html/limesurvey

# Move content to Apache root folder
RUN cp -rp /var/www/html/limesurvey/* /var/www/html && \
    chown -R www-data:www-data /var/www/html/limesurvey && \
    rm -rf /var/www/html/limesurvey

RUN chown www-data:www-data /var/lib/php5

# Copy docker-entrypoint
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME /var/www/html/upload

EXPOSE 80


ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2-foreground"]