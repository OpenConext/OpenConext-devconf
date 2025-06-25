# OpenConext Stepup config for development and testing purposes

This folder contains configuration that is needed to get an OpenConext Stepup test and development environment up and
running. You can do three related, yet distinct things using the scripts, configuration and docker compose file(s) in
this repository:
* Run an environment using the stepup production Docker images, useful for manual testing, experimentation and development
* Run the Behat (integration) tests in this repository. This requires that you use test build of the images
  (with the test tag). The test (smoketest) environment uses a databases, so it does not interfere with the manual
  environment
* Replace one or more apps with apps that run in a development container from local source, useful for
  development and debugging from a IDE.

The main configuration for each app can be found in each application's repository. The extension .dist is used for that
(parameters.yaml.dist for instance). The idea is that these configuration files contain everything necessary to get a
development environment up and running and that there is no need to change that. The containers will have a working copy
of those .dist configuration files.
This repository contains the docker-compose.yml to get all containers that are used for development up and running.

* The application containers
* A loadbalancer in front of it
* A MariaDB container for the databases.

A SQL in the directory dbschema which creates databases and users needed for OpenConext Stepup development is mounted in
the MariaDB container.

The application config directories contain the SAML key material. Those are not shipped with the application containers
to prevent accidental usage of that key material in a production environment. The docker-compose mounts the application
specific directory in /config.

# Getting everything up and running

To use this Stepup environment you need a Yubikey that supports [Yubico OTP](https://developers.yubico.com/OTP/).

## 1. Add *.dev.openconext.local hosts to yout hosts file
Create an entry in your `hosts` file (`/etc/hosts` on *nix systems)

```
127.0.0.1 selfservice.dev.openconext.local ssp.dev.openconext.local gateway.dev.openconext.local middleware.dev.openconext.local ra.dev.openconext.local demogssp.dev.openconext.local tiqr.dev.openconext.local webauthn.dev.openconext.local azuremfa.dev.openconext.local
```

## 2. Configure Yubico cloud API credentials
Create the `stepup/gateway/surfnet_yubikey.yaml` file with your Yubikey API credentials.
If you do not have API credentials, you can get them at <https://upgrade.yubico.com/getapikey/>.
You require a Yubikey to get an API key. This credential is used to verify the Yubikey OTP's against the Yubico cloud.

```yaml
surfnet_yubikey_api_client:
  credentials:
    client_id: 'YOUR_CLIENT_ID'
    client_secret: 'YOUR_SECRET'
```

## 3. Start the containers
Start the containers using docker compose:
```
docker compose up -d
```
or use the included script:
```
./start-dev-env.sh -d
```

## 4. Bootstrap the database configuration
This has to be done only once, this step is idempotent.
Initialise (bootstrap) the middleware, gateway and webauthn database schema's and push
the configuration to the middleware. This is done by running the following script:
```
./bootstrap.sh
```
Should something go wrong, you can use `clear-database.sh` script to start over, or remove the mariadb container.

## 5. Bootstap the Super RA Administrator
Bootstrap the SRAA. This will associate you Yubikey ID with the admin/admin account that has SRAA (root) rights in
the Stepup RA application.
For this, you will need to have a Yubikey that works with the Yubico Cloud.
Use the following command to bootstrap the SRAA:
```
./bootstrap-admin-sraa.sh
```
This scripts asks for a Yubikey OTP to extract the Yubikey ID.
Bootstrap will fail if you have tried to authenticate to Stepup before with the admin account or when the admin
account was already bootstrapped before. Clear the database and start over from step 4 if you're stuck.

## 6. Login to the RA application
You can now login to the RA application using the admin account. The URL is:
https://ra.dev.openconext.local
The username and password for the admin account are:
```
username: admin
password: admin
```

## 7. Start testing
There are many user accounts available for testing registration in the selfservice application.
See https://ssp.dev.openconext.local/#test-accounts for a list of test accounts.
We recommend that you use the admin account only to activate additional RA and RAA accounts and do not
use the admin account itself for testing.

The selfservice application is available at https://selfservice.dev.openconext.local
Mailcatcher is included. You can view the emails by going to http://localhost:1080

A SimpleSAMLphp SP is included to test authentication from an SP.
It can be accessed at https://ssp.dev.openconext.local/simplesaml/sp.php

# Tips

## Dealing with cookies
* The IdP has SSO. You can use https://ssp.dev.openconext.local/logout.php to destroy the SSO session at the IdP.
* The applications have sessions too, private browser windows are your friend.
* Make sure to use https:// to access the applications. Using http:// will drop the https only cookies and that will make
  the SAML authentication to the applications fail.

## Version info
You can use the included `version-info.sh` script to get the version info of the different stepup
components from the docker containers. This script will show the `version`, `revision` and `created`
tags of the running containers.

## Accessing the database from your IDE
The Maria DB container exposes its 3306 port.
So you can connect to the database with your favorite DBA tool on your host.
The connection information is:
```
host: localhost
port: 3306
user: root
password: secret
```

# Starting a project in development mode
You can mount your local directory inside a development container which contains the correct node and composer versions
for your project. To do so use the script `start-dev-env.sh`. You can use this script to mount multiple directories in
multiple containers, basically allowing you to start multiple containers in dev mode.

To mount the code in just one container:
`start-dev-env.sh webauthn:/home/username/Stepup-webauthn`
The recommended way is to use absolute paths and the script requires the name of the service and local code path to be
separated by a `:`.

To mount the code in multiple containers:
`start-dev-env.sh webauthn:/home/username/Stepup-webauthn gateway:/home/username/Stepup-gateway`
You can add as many services+local code paths that you need.
The recommended way is to use absolute paths and the script requires the name of the service and local code path to be separated by a `:`, for each service.

# Selecting the development image
The default development container used in the docker-compose.override.yml is based on the base image from
https://github.com/OpenConext/OpenConext-BaseContainers with PHP8.2, composer, xdebug and node installed. You can
override this image on a per service basis. See the included `.env.dist` for a list of the environment variables that
can be used. `.env` is in .gitignore so you can make your own changes.

# Functional testing (smoketest)
The Stepup application suite comes with a set of Behat (Gherkin) features.
These features test the Stepup applications functionally.
These tests range from simple smoke tests (can we still vet a token), to more bug report driven functional tests.
And everything in between.

These tests live in this folder: `stepup/tests/behat/features`

Custom Contexts where created to perform Stepup specific actions.
Some details about these contexts can be read about below.

## Running the test using github actions
The tests are automatically triggered on GitHub Actions when building a Pull Request.
The action is named: [`stepup-behat`](https://github.com/OpenConext/OpenConext-devconf/actions/workflows/stepup-behat.yml)

## Running the test locally

To run the tests locally you must use images that have the composer dev dependencies installed. There are prebuild
images available. These have the "test" tag.

### 1. Starting the containers in test mode
To run the behat tests you need to have a local devconf environment running and prepare it for running the behat tests.
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

The .env file is also used by `docker compose` so that you can e.g. pull the latest test image using
`docker compose pull` and other docker compose commands.

Note that you can only run one devconf environment at a time because of the port mappings.
All environments use the same ports and the same docker network names.

You can use the override to run the tests against a local version of the code. E.g.
*`$ ./start-dev-env.sh` will start the environment using test images for every component.
*`$ ./start-dev-env.sh selfservice:/path/to/SelfService` will start selfservice with local code mounted using the
  `selfservice/docker-compose.override.yml` file.

The test images are docker images that have the "test" tag set. These are not automatically build where a release tag is
set. Test images are build using the "build-push-test-docker-image" github action, the production images are not
suitable to run the behat tests because they lack the composer dev dependencies that are used by the Symfony smoketest
environment.

### Prepare the behat container

The behat container has the `OpenConext-devconf/stepup/` (this repo / directory) mounted in the container.

The behat test container is started when `APP_ENV=smoketest`. The first time you run the behat tests, you need to
install the dependencies in the container.
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
It should be straightforward to see where to add new definitions.
The contexts are not following all the clean code or solid principles. This code is messy, be warned.

Because it is hard to step debug the code that is run in a CURL based browser. It can be useful during debugging and
developing to use the `$this->diePrintingContent();` statement to see the current state. You can add an "I die" step to
a behat scenario to call this function. This outputs the URI of the browser, and the last received HTML response.

The CURL based browser does not run javascript, this means that SAML POSTs need a manual step to be submitted. You can
use the "I Submit the SAML Post" for this.

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

