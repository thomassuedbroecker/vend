#!/bin/bash

# **************** Global variables
export ROOT_PATH=$(pwd)
export CONTAINER_NAME=vend-simple-verification
export IMAGE_NAME=vend-simple-local-verification:v1.0.0
export CONTAINER_ENGINE=podman

# **************** Verify container
echo "************************************"
echo " Verify container locally"
echo "************************************"

echo "************************************"
echo " Build and run web-app"
echo "************************************"
$CONTAINER_ENGINE image list
$CONTAINER_ENGINE container list
$CONTAINER_ENGINE container stop -f  $CONTAINER_NAME
$CONTAINER_ENGINE container rm -f $CONTAINER_NAME
$CONTAINER_ENGINE image rm -f $IMAGE_NAME

$CONTAINER_ENGINE build -t $IMAGE_NAME -f Dockerfile .
pwd

$CONTAINER_ENGINE container list

$CONTAINER_ENGINE run --name=$CONTAINER_NAME \
           -it \
           -e VEND_USAGE="demo" \
           -e USER="user" \
           -e USERPASSWORD="user" \
           -e ADMINUSER="admin" \
           -e ADMINUSERPASSWORD="admin" \
           -p 3000:3000 \
           $IMAGE_NAME

$CONTAINER_ENGINE logs vend-verification
$CONTAINER_ENGINE port --all  