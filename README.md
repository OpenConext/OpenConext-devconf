This repo contains the docker compose file and configuration for setting up a OpenConext development environment using Docker.

There are two environments that can be started from this repo: One for the stepup project and one for all the other apps (called "core")

You can find more information in their respective directories (stepup and core)

Feedback welcome!

## Mac M1/M2/M3 support
This branch `feature/arm` adds support for running OpenConext on Macbooks M1/M2/M3 with arm64 processors.
It _almost_ works out of the box.  The following underlying issues should be solved to make this work without changes:
 - our upstream java images (`https://hub.docker.com/_/eclipse-temurin`) don't support arm64 in the alpine flavours; we
   should consider switching to the Ubuntu flavours.  We work around this by running amd64 containers for the java apps
   (using Rosetta).
 - our upstream bitnami mongo images don't support arm64.  The issue is that upstream ongo only officially supports
   arm64 on Ubuntu, whereas bitname build on top of Debian images.  Solved here by using a forked bitnami repo.  We
   could consider switching to the official Mongo images.


To get this to work, you need a an arm64 VM which supports Rosetta. Docker Desktop supports this, or use Parallels.
