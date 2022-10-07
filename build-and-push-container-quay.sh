#!/bin/bash

# **************** Global variables
export ROOT_PATH=$(pwd)
export IMAGE_NAME=vend-simple:v2
export URL=quay.io
export REPOSITORY=tsuedbroecker
export CONTAINER_RUNTIME=podman

$CONTAINER_RUNTIME login quay.io
$CONTAINER_RUNTIME build -t "$URL/$REPOSITORY/$IMAGE_NAME" -f Dockerfile .
$CONTAINER_RUNTIME push "$URL/$REPOSITORY/$IMAGE_NAME"
