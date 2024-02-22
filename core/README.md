# Docker compose environment for getting an OpenConext suite up and running

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
127.0.0.1 engine.dev.openconext.local manage.dev.openconext.local profile.dev.openconext.local engine-api.dev.openconext.local mujina-idp.dev.openconext.local profile.dev.openconext.local connect.dev.openconext.local teams.dev.openconext.local voot.dev.openconext.local
```

If all goes wel, you can now login. Please see the section below to find out where you can login.


## Services


|name |function     |
| --- | --- | 
|haproxy     | loadbalancer    |     
|mongo     |Mongo database for oidc and manage     |   
|mariadb   |MariaDB databases for engine and teams     |    

|name |function     |URL     |    
| --- | --- | --- | 
|engine|Engineblock, the SAML proxy |https://engine.dev.openconext.local |   
|oidcng |OpenID connect proxy     |https://connect.dev.openconext.local  |    
|profile|Profile page|https://profile.dev.openconext.local     |    
|manage|Entity registration |https://manage.dev.openconext.local     |    
|teams|Group membership app|https://teams.dev.openconext.local     |  
|mujina|Mujina IdP|htpps://mujina-idp.dev.openconext.local|

