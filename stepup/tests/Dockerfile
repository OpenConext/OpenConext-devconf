FROM ghcr.io/openconext/openconext-basecontainers/php72-apache2-node16-composer2:latest
RUN apt-get update && \
  apt-get install -y mariadb-client && \
  apt-get install -y ca-certificates curl && \
  install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
  chmod a+r /etc/apt/keyrings/docker.asc && \
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null && \
  apt-get update &&  \
  apt install -y docker-ce docker-ce-cli containerd.io

WORKDIR /config/tests/behat
