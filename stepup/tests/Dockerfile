FROM ghcr.io/openconext/openconext-basecontainers/php72-apache2-node16-composer2:latest
RUN apt-get update && \ 
  apt-get install -y docker.io mariadb-client 
WORKDIR /config/tests/behat
RUN mkdir /var/www/html/public
