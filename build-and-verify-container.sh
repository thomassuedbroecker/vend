#!/bin/bash

# **************** Global variables
export ROOT_PATH=$(pwd)
export CONTAINER_NAME=vend-simple-verification
export IMAGE_NAME=vend-simple-local-verification:v1

# **************** Verify container
echo "************************************"
echo " Verify container locally"
echo "************************************"

echo "************************************"
echo " Build and run web-app"
echo "************************************"
docker image list
docker container list
docker container stop -f  $CONTAINER_NAME
docker container rm -f $CONTAINER_NAME
docker image rm -f $IMAGE_NAME

docker build -t $IMAGE_NAME -f Dockerfile .
pwd

docker container list

docker run --name=$CONTAINER_NAME \
           -it \
           -e VEND_USAGE="demo" \
           -e USER="user" \
           -e USERPASSWORD="user" \
           -e ADMINUSER="admin" \
           -e ADMINUSERPASSWORD="admin" \
           -p 3000:3000 \
           $IMAGE_NAME

docker logs vend-verification
docker port --all  