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
127.0.0.1 selfservice.dev.openconext.local ssp.dev.openconext.local gateway.dev.openconext.local middleware.dev.openconext.local ra.dev.openconext.local demogssp.dev.openconext.local tiqr.dev.openconext.local webauthn.dev.openconext.local azuremfa.dev.openconext.local
```

Secondly you need to create the `stepup/gateway/surfnet_yubikey.yaml` filewith your Yubikey API credentials. If you do not have API credentials, you can get them at <https://upgrade.yubico.com/getapikey/>. You require a Yubikey to get an API key.

```yaml
surfnet_yubikey_api_client:
  credentials:
    client_id: 'YOUR_CLIENT_ID'
    client_secret: 'YOUR_SECRET'
```

You should then get the apps initialised
You can then bring up the containers using docker compose:

Initialise the middelware database:
```
docker compose up -d
docker compose exec middleware /var/www/html/bin/console  doctrine:migrations:migrate --env=prod --em=deploy
docker compose exec middleware chown -R www-data /var/www/html/var/cache/prod/
```

Then the webauthn db
```
docker compose exec webauthn /var/www/html/bin/console  doctrine:migrations:migrate --env=prod
```

Then you will need to provision the middleware config:
```
cd middleware
./middleware-push-config.sh
./middleware-push-whitelist.sh
./middleware-push-institution.sh
```
Then, bootstrap the SRAA. For this, you will need to have a Yubikey. Replace Yubikey_ID with the number that is printed on your yubikey. It should be 8 characters. If it is less, prepend it with 0's
```
docker compose exec middleware  /var/www/html/bin/console middleware:bootstrap:identity-with-yubikey urn:collab:person:dev.openconext.local:admin dev.openconext.local "Your Name" Your@email nl_NL Yubikey_ID
```

Mailcatcher is included. You can view the email by going to http://localhost:1080

A SimpleSAMLPHP sp is included. It can be accessed at https://ssp.dev.openconext.local/simplesaml/sp.php

# Starting a project in development mode

You can mount your local directory inside a development container which contains the correct node and composer versions for your project. To do so use the script start-dev-env.sh. You can use this script to mount multiple directories in multiple containers, basically allowing you to start multiple containers in dev mode.

To mount the code in just one container:
`start-dev-env.sh webauthn:/home/dan/Stepup-webauthn`
The recommended way is to use absolute paths and the script requires the name of the service and local code path to be separated by a `:`.

To mount the code in multiple containers:
`start-dev-env.sh webauthn:/home/dan/Stepup-webauthn gateway:/home/dan/Stepup-gateway`
You can add as many services+local code paths that you need.
The recommended way is to use absolute paths and the script requires the name of the service and local code path to be separated by a `:`, for each service.

# Accessing the database from your IDE
The Maria DB container exposes her 3306 port to the outside. So you should be able to connect to the database with
your favorite DBA tool. In PHPStorm I was able to connect to the `mariadb` host by using these setting.

```
host: localhost
user: root
password: you know the secret ;)
```

# PHP 8.2 for development
The default development container is based on the base image with PHP7.2. You can override this on a per service basis. Uncomment the appropiate line for this in the file ".env" so it uses the PHP8.2 container. An .env.dist is included that you can use to have your own .env. file. .env is in .gitigore so you can make your own changes.

# Functional testing
The stepup application suite comes with a set of Behat (Gherkin) features. These features test the stepup applications
functionally. These tests range from simple smoketests (can we still vet a token), to more bug report driven
functional tests. And everything in between.

These tests live in this folder: `stepup/tests/behat/features`

Custom Contexts where created to perform Stepup specific actions. Some details about these contexts can be read about below.

## Running the tests
1. The tests are automatically triggered on GitHub Actions when building a Pull Request. The action is named: [`stepup-behat`](https://github.com/OpenConext/OpenConext-devconf/actions/workflows/stepup-behat.yml)
2. Run them manually.

Step two can be achieved by following these actions.

1: You must instruct the `devconf` environment that you want to run functional tests.
1. Option 1: Copy the `.env.test` to be the `.env`
2. Option 2: Add these two lines to your existing `.env` file

```shell
APP_ENV=smoketest
STEPUP_VERSION=test
```

2: Next you should start the devconf containers in test mode
1. `$ ./start-dev-env.sh` will start the environment using test images for every component.
2. `$ ./start-dev-env.sh selfservice:/path/to/SelfService` to start certain components with local code mounted (useful during development)
3. Choose if you want to run the containers in the back- or foreground.

3: Once the containers are up and running, you can run the behat tests
1. Install the required dependencies in the container `$ docker compose exec behat composer install`
2. Open a shell in the `behat` container `$ docker compose exec behat bash`
3. Run the tests:
   1. `./behat` will run all available behat tests that are not excluded using the `@SKIP` tag
   2. `./behat features/ra.feature` will only run the `ra.feature` found in the features folder
   3. `./behat features/ra.feature:20` will only run the scenario found on line 20 of the `ra.feature`
   4. TODO: `./behat --filter=selfservice` will only run features marked with the `@selfservice` tag

## Writing tests
Many of the step definitions are coded in our own Contexts. These contexts are divided into five main contexts.
It should be straightforward where to add new definitions. The contexts are not following all the clean code or solid principles. This code is messy, be warned.

It can be useful during debugging to use the `$this->diePrintingContent();` statement. This outputs the URI of the browser, and the last received html response. As it is hard to step debug the code that is run in a CURL based browser.

TODO: Mark your tests with at least one of the pre-defined tags:

`selfservice`
`ra`
`gateway`
`middleware`
`tiqr`
`demogssp`
`webauthn`

Note that these tags match the `devconf` names given to the different components.
