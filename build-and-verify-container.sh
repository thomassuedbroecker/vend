#!/bin/bash

# **************** Global variables
export ROOT_PATH=$(pwd)

# **************** Verify container
echo "************************************"
echo " Verify container locally"
echo "************************************"

echo "************************************"
echo " Build and run web-app"
echo "************************************"
docker image list
docker container list
docker container stop -f  "vend-verification"
docker container rm -f "vend-verification"
docker image rm -f "vend-local-verification:v1"

docker build -t "vend-local-verification:v1" -f Dockerfile .
pwd

docker container list

docker run --name="vend-verification" \
           -it \
           --mount type=bind,source="$(pwd)"/accesscodes,target=/usr/src/app/accesscodes \
           --mount type=bind,source="$(pwd)"/logs,target=/usr/src/app/logs \
           -e VEND_USAGE="demo" \
           -e USER="user" \
           -e USERPASSWORD="user" \
           -e ADMINUSER="admin" \
           -e ADMINUSERPASSWORD="admin" \
           -p 3000:3000 \
           "vending-local-verification:v1"

docker logs vend-verification
docker port --all  