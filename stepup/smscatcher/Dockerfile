# SMSCatcher - a "mailcatcher for SMS" emulating the Spryng REST API v1.
# Uses the same PHP 8.5 Apache base image as the rest of the OpenConext Stepup project.
# (Falls back to the upstream image it is based on:
#  FROM docker.io/library/php:8.5-apache-trixie)
FROM ghcr.io/openconext/openconext-basecontainers/php85-apache2:latest

# Route all requests through the front controller (mod_rewrite is already
# enabled in the base image; make sure .htaccess is honoured in the docroot).
RUN a2enmod rewrite \
    && { \
        echo '<Directory /var/www/html>'; \
        echo '    AllowOverride All'; \
        echo '</Directory>'; \
    } > /etc/apache2/conf-available/smscatcher.conf \
    && a2enconf smscatcher

COPY public/ /var/www/html/

# Captured messages are stored in this JSON file inside the container.
# Override with -e SMSCATCHER_PERSIST_PATH=... or mount a volume on /tmp.
ENV SMSCATCHER_PERSIST_PATH=/tmp/smscatcher-messages.json

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s \
    CMD curl -fsS http://127.0.0.1/api/health || exit 1

# ENTRYPOINT/CMD (apache2-foreground) are inherited from the base image.
