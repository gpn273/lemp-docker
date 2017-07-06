FROM ubuntu:16.04

# Docker Settings
ENV MYSQL_PASSWORD password
ENV USER graham

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN mkdir /var/run/sshd
RUN mkdir /run/php

# No tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get upgrade -y

# Basics
RUN apt-get -y install python-setuptools curl git nano sudo unzip openssh-server openssl vim htop
RUN apt-get -y install mysql-server mysql-client nginx php-fpm php-mysql

# MySQL Password
RUN echo "mysql-server mysql-server/root_password ${MYSQL_PASSWORD}" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again ${MYSQL_PASSWORD}" | debconf-set-selections

# PHP
RUN apt-get install -y php7.0-fpm php7.0-cli php7.0-mcrypt php7.0-gd php7.0-mysql php7.0-curl php7.0-mbstring php-xml php7.0-bcmath php7.0-zip

# Clean-up
RUN rm -rf /var/lib/apt/lists/*

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/explicit_defaults_for_timestamp = true\nbind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# nginx config
RUN sed -i -e"s/user\s*www-data;/user ${USER} www-data;/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 20M/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/user\s*=\s*www-data/user = ${USER}/g" /etc/php/7.0/fpm/pool.d/www.conf
# replace # by ; RUN find /etc/php/7.0/mods-available/tmp -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

RUN useradd -m -d /home/${USER} -p $(openssl passwd -1 'password') -s /bin/bash ${USER}
RUN usermod -a -G root ${USER}
RUN usermod -a -G www-data ${USER}
RUN usermod -a -G sudo ${USER}

# Powerline Font
RUN git clone https://github.com/powerline/fonts.git /home/${USER}/fonts
RUN bash /home/${USER}/fonts/install.sh --silent

# Bash-it
RUN git clone --depth=1 https://github.com/Bash-it/bash-it.git /home/${USER}/.bash_it

# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

RUN rm -rf /etc/nginx/sites-enabled
ADD nginx/sites-enabled /etc/nginx/sites-enabled

# Initialization and Startup Script
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

#NETWORK PORTS
# private expose
EXPOSE 9011
EXPOSE 3306
EXPOSE 80
EXPOSE 22

CMD ["/bin/bash", "/entrypoint.sh"]
