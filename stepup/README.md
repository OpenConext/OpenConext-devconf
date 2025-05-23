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

Secondly you need to create the `stepup/gateway/surfnet_yubikey.yaml` file with your Yubikey API credentials.
If you do not have API credentials, you can get them at <https://upgrade.yubico.com/getapikey/>.
You require a Yubikey to get an API key. There credential are used to verify the Yubikey OTP's.

```yaml
surfnet_yubikey_api_client:
  credentials:
    client_id: 'YOUR_CLIENT_ID'
    client_secret: 'YOUR_SECRET'
```

Start the containers using docker compose:
```
docker compose up -d
```
or use the included script:
```
./start-dev-env.sh
```

Initialise (bootstrap) the middleware, gateway and webauthn database schema's and push
the configuration to the middleware. This is done by running the following script:
```
./bootstrap.sh
```

Then, bootstrap the SRAA. For this, you will need to have a Yubikey.
Use the following command to bootstrap the SRAA:
```
./bootstrap-admin-sraa.sh
```

You can now login to the RA application using the admin account. The URL is:
https://ra.dev.openconext.local
The username and password for the admin account are:
```
username: admin
password: admin
```

There are many user accounts available for testing registration in the selfservice application.
See https://ssp.dev.openconext.local/#test-accounts for a list of test accounts.
We recommend that you use the admin account only to activate additional RA and RAA accounts and do not
use the admin account itself for testing.

The selfservice application is available at https://selfservice.dev.openconext.local
Mailcatcher is included. You can view the emails by going to http://localhost:1080

A SimpleSAMLPHP SP is included to test authentication from an SP.
It can be accessed at https://ssp.dev.openconext.local/simplesaml/sp.php

# Version info
You can use the included `version-info.sh` script to get the version info of the different stepup
components from the docker containers. This script will show the `version`, `revision` and `created`
tags of the running containers.

# Starting a project in development mode
You can mount your local directory inside a development container which contains the correct node and composer versions
for your project. To do so use the script `start-dev-env.sh`. You can use this script to mount multiple directories in
multiple containers, basically allowing you to start multiple containers in dev mode.

To mount the code in just one container:
`start-dev-env.sh webauthn:/home/dan/Stepup-webauthn`
The recommended way is to use absolute paths and the script requires the name of the service and local code path to be
separated by a `:`.

To mount the code in multiple containers:
`start-dev-env.sh webauthn:/home/dan/Stepup-webauthn gateway:/home/dan/Stepup-gateway`
You can add as many services+local code paths that you need.
The recommended way is to use absolute paths and the script requires the name of the service and local code path to be separated by a `:`, for each service.

# Accessing the database from your IDE
The Maria DB container exposes its 3306 port.
So you can connect to the database with your favorite DBA tool on your host.
The connection information is:
```
host: localhost
port: 3306
user: root
password: secret
```

# PHP 8.2 for development
The default development container is based on the base image with PHP7.2.
You can override this on a per service basis.
Uncomment the appropriate line for this in the file ".env" so it uses the PHP8.2 container.
An .env.dist is included that you can use to have your own .env file.
.env is in .gitignore so you can make your own changes.

# Functional testing
The stepup application suite comes with a set of Behat (Gherkin) features.
These features test the stepup applications functionally.
These tests range from simple smoketests (can we still vet a token), to more bug report driven functional tests.
And everything in between.

These tests live in this folder: `stepup/tests/behat/features`

Custom Contexts where created to perform Stepup specific actions.
Some details about these contexts can be read about below.

## Running the using github actions
The tests are automatically triggered on GitHub Actions when building a Pull Request.
The action is named: [`stepup-behat`](https://github.com/OpenConext/OpenConext-devconf/actions/workflows/stepup-behat.yml)

## Running the test locally

### Starting the containers in test mode
To run the test you need to have a local devconf environment running and prepare it for running the behat tests.
The easiest way to do this is to copy the `.env.test` file to `.env`.
The .env is sourced by the `start-dev-env.sh` script and sets these two environment variables:
```shell
APP_ENV=smoketest
STEPUP_VERSION=test
```

The above will start the environment with the test images for every component, it will also use _test databases.
E.g. `middleware` will become `middleware_test`, `gateway` will become `gateway_test`, etc.
This way your local dev environment is not affected by running the tests if you use the same devconf environment
for both smoke testing and other testing / development.

Note that you can only run one devconv environment at a time because of the port mappings.
All environments use the same ports and the same docker network names.

You can use the override to run the tests against a local version of the code. E.g.
*`$ ./start-dev-env.sh` will start the environment using test images for every component.
*`$ ./start-dev-env.sh selfservice:/path/to/SelfService` will start selfservice with local code mounted

### Prepare the behat container

The first time you run the behat tests, you need to install the dependencies in the container
```shell
docker compose exec behat composer install
```

### Running the tests

Execute behat in the behat container:
- `docker compose exec behat ./behat` will run all available behat tests that are not excluded using the `@SKIP` tag
- `docker compose exec behat ./behat features/ra.feature` will only run the `ra.feature` found in the features folder
- `docker compose exec behat ./behat features/ra.feature:20` will only run the scenario found on line 20 of the `ra.feature`

## Writing tests
Many of the step definitions are coded in our own Contexts. These contexts are divided into five main contexts.
It should be straightforward where to add new definitions.
The contexts are not following all the clean code or solid principles. This code is messy, be warned.

It can be useful during debugging to use the `$this->diePrintingContent();` statement.
This outputs the URI of the browser, and the last received html response.
As it is hard to step debug the code that is run in a CURL based browser.

TODO: Mark your tests with at least one of the pre-defined tags:
- `selfservice`
- `ra`
- `gateway`
- `middleware`
- `tiqr`
- `demogssp`
- `webauthn`

These tags match the `devconf` names given to the different components.

After that we can use the tags to run only the tests that are relevant for a specific component.
E.g.: `docker compose exec behat ./behat --filter=selfservice` will only run features marked with the `@selfservice` tag

