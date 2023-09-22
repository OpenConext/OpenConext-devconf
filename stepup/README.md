# OpenConext Stepup config for development and testing purposes

This folder contains configuration that is needed to get an OpenConext Stepup development environment up and running.

The main configuration for each app can be found in each application repository. The extension .dist is used for that (parameters.yaml.dist for instance). The idea is that these configuration files contain everything necessary to get a development environment up and running and that there is no need to change that. The containers will have a working copy of those .dist configuration files.
This repository contains the docker-compose.yml to get all containers that are used for development up and running.

* The application containers
* A loadbalancer in front of it
* A MariaDB container for the databases.

A SQL in the directory dbschema  which creates databases and users needed for OpenConext Stepup development is mounted in the MariaDB container.

The application config directories contain the SAML key material. Those are not shipped with the application containers to prevent accidental usage of that key material in a production environment. The docker-compose mounts the application specific directory in /config.

## Getting everything up and running

First, you need to create an entry in your hosts file (`/etc/hosts` on *nix systems)

```text
127.0.0.1 selfservice.dev.openconext.local webauthn.dev.openconext.local ssp.dev.openconext.local gateway.dev.openconext.local middleware.dev.openconext.local ra.dev.openconext.local demogssp.dev.openconext.local
```

Secondly you need to create the `stepup/gateway/surfnet_yubikey.yaml` filew ith your Yubikey API credentials. If you do not have API credentials, you can get them at <https://upgrade.yubico.com/getapikey/>. You require a Yubikey to get an API key.

```yaml
surfnet_yubikey_api_client:
  credentials:
    client_id: 'YOUR_CLIENT_ID'
    client_secret: 'YOUR_SECRET'
```

You can then bring up the containers using docker compose:

```text
docker-compose up -d
```

You should then get the apps initialised.

Initialise the middelware, gateway and webauthn database schema's and push the configuration of the middleware to the database:

```shell
./init-db.sh
```

Then, bootstrap the SRAA user. For this, you will need to have a Yubikey. Replace `Yubikey_ID` in the command below with the serial number of your your Yubikey. This number is printed on your Yubikey. You can also get it by converting the first 12 characters from an OTP from your Yubikey from ModHex to decimal using <https://developers.yubico.com/OTP/Modhex_Converter.html>. The serial number must be at least 8 digits long. If it has less digits, prepend it with 0's.

This associates the admin account with your Yubikey. The account has SRAA rights. You can then use your Yubikey to log in as user `admin` with password `admin`. Note that you must run this command before the first time you log in with the admin account to the SA or RA, otherwise this command will fail because the admin identity already exists.

```shell
docker compose exec middleware /var/www/html/bin/console middleware:bootstrap:identity-with-yubikey urn:collab:person:dev.openconext.local:admin dev.openconext.local "Your Name" Your@email en_GB Yubikey_ID
```

You can now login to the self-service portal at <https://selfservice.dev.openconext.local> and login to the RA portal at <https://ra.dev.openconext.local> using your admin/admin account.

Mailcatcher is included. You can view the email by going to <http://localhost:1080>

A SimpleSAMLphp SP for testing authentication from an SP is included. It can be accessed at <https://ssp.dev.openconext.local/simplesaml/sp.php>

## Starting a project in development mode

You can mount your local directory inside a development container which contains the correct node and composer versions for your project. To do so use the script start-dev-env.sh. It takes two parameters: the service name and the local directory to mount. Example: start-dev-env.sh webauthn /home/dan/Stepup-webauthn (the recommended way would be to use absolute paths). The startup script uses these two parameters to read the docker compose override file from the service's directory and replace the code path in that file (by reading it as an env var)
