The haproxy,.crt file here is a copy of the ../../core/haproxy/haproxy.crt.  It is mounted in the containers to be added
to the CA trust store.  It cannot be a symlink, because that would break the file in the container.
