
# Get the tests up and running
The stepup directory is mounted in /config. All tests are present in this directory. 
All the Stepup containers have a test variant available. These are tagged with :test eg:

```
ghcr.io/openconext/stepup-gateway/stepup-gateway:test
```

These are automatically started when the correct variable is set in the .env in the directory where docker-compose.yml is located.
An environment file is provided. Copy it into place to use it:
```
cp .env.test .env
```

You can the start the environment in test mode (APP_ENV=smoketest does the magic inside the containers)
A seperate behat container is provided. It is defined in a docker compose override file. Start it like this:
```
docker compose -f docker-compose.yml -f docker-compose-behat.yml up -d
```

You can now use the shell inside the behat container to start the behat tests.

Enter the container:
```
docker compose exec -ti behat bash
```

Now you need to install behat
```
composer install --ignore-platform-req=ext-bcmath
```
And you can now run the tests
```
vendor/behat/behat/bin/behat
```
TODO
- The bootstrap process is not working as it should. The renaming of stepup.example.com to dev.openconext.local might be an issue
- Make start-dev-env.sh compatible by adding a commandline option to start the environment in smoketest mode
- Think of a way to do this in GitHub actions
- Make the logging in all containers docker compatible (log to stdout)

