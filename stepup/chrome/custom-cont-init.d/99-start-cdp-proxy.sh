#!/usr/bin/with-contenv bash
# Start the nginx proxy that exposes Chromium's DevTools endpoint (loopback
# 127.0.0.1:9223, see CHROME_CLI) on 0.0.0.0:9222 for the other containers.
# Mounted into /custom-cont-init.d, which the linuxserver s6-overlay runs at
# container init.
set -eu

/usr/sbin/nginx -c /etc/nginx-cdp-proxy.conf

echo "Started CDP proxy: 0.0.0.0:9222 -> 127.0.0.1:9223"
