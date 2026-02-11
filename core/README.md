# Docker compose environment for getting an OpenConext suite up and running

## Introduction

This repo contains a docker compose and some configuration to get you started with getting an OpenConext installation up and running on your own machine. Please note that you should not run this in production. It is meant for evaluation and testing purposes.


## Getting started

### The first time
If you are doing this for the first time, you need to run a script to seed the environment:

```
./scripts/init.sh
```

### After initialisation
To get all services up and running you must have docker compose installed. Enter this command to get things up and running:

```
docker compose up -d
```

You will also need to tell your local machine where to find the hosts.
Add the following line in your hosts file (/etc/hosts )
```
127.0.0.1 engine.dev.openconext.local manage.dev.openconext.local profile.dev.openconext.local engine-api.dev.openconext.local mujina-idp.dev.openconext.local profile.dev.openconext.local connect.dev.openconext.local teams.dev.openconext.local voot.dev.openconext.local pdp.dev.openconext.local invite.dev.openconext.local welcome.dev.openconext.local
```

If all goes wel, you can now login. Please see the section below to find out where you can login.

*Please note that this starts the environment with the profile oidc. Bringing it down requires this command:*
```
docker compose --profile oidc down
```

## Services

### Loadbalancer and databases
|name |function     |
| --- | --- |
|haproxy     | loadbalancer    |
|mongo     |Mongo database for oidc and manage     |
|mariadb   |MariaDB databases for engine and teams     |


### OpenConext apps
| name    | function                    | URL                                     |
| ---     | ---                         | ---                                     |
| engine  | Engineblock, the SAML proxy | https://engine.dev.openconext.local     |
| oidcng  | OpenID connect proxy        | https://connect.dev.openconext.local    |
| profile | Profile page                | https://profile.dev.openconext.local    |
| manage  | Entity registration         | https://manage.dev.openconext.local     |
| teams   | Group membership app        | https://teams.dev.openconext.local      |
| mujina  | Mujina IdP                  | https://mujina-idp.dev.openconext.local |
| voot    | Voot membership API         | https://voot.dev.openconext.local       |
| pdp     | Policy Decicions API        | https://pdp.dev.openconext.local        |
| invite  | Invite based groups         | https://invite.dev.openconext.local     |
| welcome | Invite UI                   | https://invite.dev.openconext.local     |

### Docker compose profiles

Since the OpenConext suite is composed of multiple docker containers, you can use the following [Docker compose profiles](https://docs.docker.com/compose/profiles/) to switch between them.

- No profile: Starts the core services: Engineblock, manage, mujina and profile (plus loadbalancer and databases).
- oidc: Starts oidc as well.
- teams: Starts services needed for teams (oidcng, voot and teams)
- invite: Starts services needed for Openconext-Invite (oidcng, voot and teams)
- extras: Starts extras (currently pdp)

If you want to start all services, you can use extras. A profile can be started by using the --profile argument to the `docker compose up` command. For example:
```
docker compose up -d --profile extras
```

# Starting a PHP project in development mode (only lifecycle, profile and engineblock)

You can mount your local directory inside a development container which contains the correct node and composer versions for your project. To do so use the script start-dev-env.sh. You can use this script to mount multiple directories in multiple containers, basically allowing you to start multiple containers in dev mode.

To mount the code in just one container:
`start-dev-env.sh profile:../../OpenConext-profile`
The recommended way is to use absolute paths and the script requires the name of the service and local code path to be separated by a `:`.

To mount the code in multiple containers:
`start-dev-env.sh profile:../../OpenConext-profile userlifecycle:../../OpenConext-user-lifecycle`
You can add as many services+local code paths that you need.
The recommended way is to use absolute paths and the script requires the name of the service and local code path to be separated by a `:`, for each service.

# Tips

To start engine in local development environment use from this directory;

Ensure a file `.env` exists with:
```shell
APP_ENV=dev
APP_DEBUG=true
APP_SECRET=secret
```
```shell
./start-dev-env.sh engine:../../OpenConext-engineblock/
```
To change the running env, just edit `APP_ENV=ci` for example and re-run `./start-dev-env.sh engine:../../OpenConext-engineblock/`. You do not have to recreate all services, only to reload engineblock.

## Pulling latest containers
When experiencing weird errors, it can help to start the dev env using the `--pull always` and `--force-recreate` parameters, to ensure all containers are up-to-date.
For example, use `./start-dev-env.sh engine:../../OpenConext-engineblock/ -- --pull always --force-recreate`.
