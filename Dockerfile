FROM alpine:3.8

# set arguments
ARG UID

# add me user
RUN adduser -D -u${UID} me me,nginx

# install required packages
RUN apk update && \
    apk add supervisor && \
    apk add nginx && \
    apk add php7 && \
    apk add php7-fpm && \
    apk add php7-session && \
    apk add php7-pdo && \
    apk add php7-pdo_mysql && \
    apk add php7-json && \
    apk add php7-phar && \
    apk add php7-iconv && \
    apk add php7-mbstring && \
    apk add php7-tokenizer && \
    apk add php7-dom && \
    apk add php7-xmlwriter && \
    apk add php7-xml && \
    apk add mariadb && \
    apk add mariadb-client

# create other required dirs
RUN mkdir -p /etc/supervisor.d && \
    mkdir -p /run/me && \
    mkdir -p /run/me/nginx && \
    mkdir -p /run/me/mysqld && \
    mkdir -p /var/log/me && \
    mkdir -p /var/log/me/nginx && \
    mkdir -p /var/log/me/php7 && \
    chown me:me -R /run/me && \
    chown me:me -R /var/log/me

# copy supervisor configs
COPY .docker/supervisor/app.ini /etc/supervisor.d/app.ini

# copy nginx config
COPY .docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY .docker/nginx/app.conf /etc/nginx/conf.d/app.conf

# copy php config
COPY .docker/php/www.conf /etc/php7/php-fpm.d/www.conf
COPY .docker/php/php-fpm.conf /etc/php7/php-fpm.conf
COPY .docker/php/php.ini /etc/php7/php.ini

# configure mariadb
# see https://wiki.alpinelinux.org/wiki/MariaDB
COPY .docker/mariadb/my.cnf /etc/mysql/my.cnf
RUN mysql_install_db --user=me --datadir=/var/lib/mysql
RUN nohup mysqld --user=me & \
    sleep 10s && \
    mysqladmin -u root password "p@ssword" && \
    echo "GRANT ALL ON *.* TO me@'127.0.0.1' IDENTIFIED BY 'p@ssword' WITH GRANT OPTION;" > /tmp/sql && \
    echo "GRANT ALL ON *.* TO me@'localhost' IDENTIFIED BY 'p@ssword' WITH GRANT OPTION;" >> /tmp/sql && \
    echo "GRANT ALL ON *.* TO me@'::1' IDENTIFIED BY 'p@ssword' WITH GRANT OPTION;" >> /tmp/sql && \
    echo "DELETE FROM mysql.user WHERE User='';" >> /tmp/sql && \
    echo "DROP DATABASE test;" >> /tmp/sql && \
    echo "FLUSH PRIVILEGES;" >> /tmp/sql && \
    cat /tmp/sql | mysql -u root --password="p@ssword" && \
    rm /tmp/sql

# install php cpmposer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    chmod +x /usr/bin/composer

# install adminer
COPY .docker/nginx/adminer.conf /etc/nginx/conf.d/adminer.conf
RUN mkdir -p /var/www/adminer
COPY .docker/adminer/adminer-4.6.3.php /var/www/adminer/adminer.php

STOPSIGNAL SIGTERM

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
