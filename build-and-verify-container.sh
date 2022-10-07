#!/bin/bash

# **************** Global variables
export ROOT_PATH=$(pwd)
export CONTAINER_NAME=vend-simple-verification
export IMAGE_NAME=vend-simple-local-verification:v1
export CONTAINER_RUNTIME=podman

# **************** Verify container
echo "************************************"
echo " Verify container locally"
echo "************************************"

echo "************************************"
echo " Build and run vend example"
echo "************************************"
$CONTAINER_RUNTIME image list
$CONTAINER_RUNTIME container list
$CONTAINER_RUNTIME container stop -f  $CONTAINER_NAME
$CONTAINER_RUNTIME container rm -f $CONTAINER_NAME
$CONTAINER_RUNTIME image rm -f $IMAGE_NAME

$CONTAINER_RUNTIME build -t $IMAGE_NAME -f Dockerfile .
pwd

$CONTAINER_RUNTIME container list

$CONTAINER_RUNTIME run --name=$CONTAINER_NAME \
           -it \
           -e VEND_USAGE="demo" \
           -e USER="user" \
           -e USERPASSWORD="user" \
           -e ADMINUSER="admin" \
           -e ADMINUSERPASSWORD="admin" \
           -p 3000:3000 \
           $IMAGE_NAME

$CONTAINER_RUNTIME logs vend-verification
$CONTAINER_RUNTIME port --all  