# OpenConext Stepup config for development and testing purposes

This folder contains configuration that is needed to get an OpenConext Stepup developmentenvironment up and running. 

The main configuration for each app can be found in each application repository. The extension .dist is used for that (parameters.yaml.dist for instance). The idea is that these configuration files contain everything necessary to get a development environment up and running and that there is no need to change that. The containers will have a working copy of those .dist configuration files.
This repository contains the docker-compose.yml to get all containers that are used for development up and running.

* The application containers 
* A loadbalancer in front of it
* A MariaDB container for the databases.

A SQL in the directory dbschema  which creates databases and users needed for OpenConext Stepup development is mounted in the MariaDB container. 

The application config directories contain the SAML key material. Those are not shipped with the application containers to prevent accidental usage of that key material in a production environment. The docker-compose mounts the application specific directory in /config. 

# Getting everything up and running

First, you need to create an entry in your hosts file (/etc/hosts on *nix systems)

```
127.0.0.1 selfservice.dev.openconext.local webauthn.dev.openconext.local ssp.dev.openconext.local gateway.dev.openconext.local middleware.dev.openconext.local ra.dev.openconext.local demogssp.dev.openconext.local
```
You can then bring up the docker-compose:

```
docker-compose up -d
```

You should then get the apps initialised

Initialise the middelware database:
```
docker compose exec middleware /var/www/html/bin/console  doctrine:migrations:migrate --env=prod --em=deploy
```

Then the webauthn db
```
docker compose exec webauthn /var/www/html/bin/console  doctrine:migrations:migrate --env=prod

```
Then you will need to provision the middleware config:
```
cd middleware
sh middleware-push-config.sh
sh middleware-push-whitelist.sh
sh middleware-push-institution.sh
```
Then, bootstrap the SRAA. For this, you will need to have a Yubikey. Replace Yubikey_ID with the number that is printed on your yubikey. It should be 8 characters. If it is less, prepend it with 0's
```
docker compose exec middleware  /var/www/html/bin/console middleware:bootstrap:identity-with-yubikey urn:collab:person:dev.openconext.local:admin dev.openconext.local "Your Name" Your@email nl_NL Yubikey_ID
```

You also need a Yubikey API key for your Yubikey to work. You can get it here:
https://upgrade.yubico.com/getapikey/
Create the following file "stepup/gateway/surfnet_yubikey.yaml" which should contain:

```
surfnet_yubikey_api_client:
  credentials:
    client_id: 'YOUR_CLIENT_ID'
    client_secret: 'YOUR_SECRET'
```

After this, the cache of the gateway needs to be cleared:
```
docker compose exec gateway /var/www/html/bin/console cache:clear --env=prod
```




