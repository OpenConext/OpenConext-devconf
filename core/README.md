# Docker compose environment for getting an OpenConext suite up and running

## Introduction

This repo contains a docker compose and some configuration to get you started with getting an OpenConext installation up and running on your own machine. Please note that you should not run this in production. It is meant for evaluation and testing purposes.


## Getting started

To get all services up and running you must have docker compose installed. Enter this command to get things up and running:

```
docker compose up -d
```

If you are doing this for the first time, you need to run a script to seed the environment:

```
./scripts/init.sh
```

You will also need to tell your local machine where to find the hosts. 
Add the following line in your hosts file (/etc/hosts )
```
127.0.0.1 engine.dev.openconext.local manage.dev.openconext.local profile.dev.openconext.local engine-api.dev.openconext.local mujina-idp.dev.openconext.local profile.dev.openconext.local connect.dev.openconext.local teams.dev.openconext.local voot.dev.openconext.local pdp.dev.openconext.local
```

If all goes wel, you can now login. Please see the section below to find out where you can login.

*please not that this starts the environment with the profile oidc. Bringing it down requires this command:*
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
|name |function     |URL     |
| --- | --- | --- | 
|engine  |Engineblock, the SAML proxy |https://engine.dev.openconext.local |
|oidcng  |OpenID connect proxy   |https://connect.dev.openconext.local     |
|profile |Profile page           |https://profile.dev.openconext.local     |
|manage  | Entity registration   |https://manage.dev.openconext.local      |
|teams   | Group membership app  |https://teams.dev.openconext.local       |
|mujina  | Mujina IdP            |https://mujina-idp.dev.openconext.local  |
|voot    | Voot membership API   |https://voot.dev.openconext.local        |
|pdp     | Policy Decicions API  |https://pdp.dev.openconext.local         |

### Docker compose profiles

Since the OpenConext suite is composed of multiple docker containers, you can use the following [Docker compose profiles](https://docs.docker.com/compose/profiles/) to switch between them.

- No profile: Starts the core services: Engineblock, manage, mujina and profile (plus loadbalancer and databases).
- oidc: Starts oidc as well.
- teams: Starts services needed for teams (oidcng, voot and teams)
- extras: Starts extras (currently pdp)

If you want to start all services, you can use extras. A profile can be started by using the --profile argument to the `docker compose up` command. For example:
```
docker compose up -d --profile extras
```


