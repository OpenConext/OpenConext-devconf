# Chrome DevTools (CDP) proxy

The `chrome` service in `../docker-compose.yml` runs `lscr.io/linuxserver/chromium`.
Since Chromium ~M113 the remote debugging server is only bound to `127.0.0.1` and the `--remote-debugging-address`
switch is ignored. So `--remote-debugging-port` only makes the DevTools endpoint reachable from inside the
container.
To allow Behat tests that use `http://chrome.dev.openconext.local:9222/` to work an nginx proxy is started inside the container that binds to `0.0.0.0:9222` and forwards to `127.0.0.1:9223`.

- Mount `nginx-cdp-proxy.conf` with the nginx proxy configuration at `/etc/nginx-cdp-proxy.conf`.
- Mount `custom-cont-init.d/99-start-cdp-proxy.sh` with the command to start nginx at
  `/custom-cont-init.d/`
