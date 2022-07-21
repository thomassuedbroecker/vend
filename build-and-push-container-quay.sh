#!/bin/bash

# **************** Global variables
export ROOT_PATH=$(pwd)
export IMAGE_NAME=vend-simple:v1
export URL=quay.io
export REPOSITORY=tsuedbroecker
export CONTAINER_ENGINE=podman

$CONTAINER_ENGINE login quay.io
$CONTAINER_ENGINE build -t "$URL/$REPOSITORY/$IMAGE_NAME" -f Dockerfile .
$CONTAINER_ENGINE push "$URL/$REPOSITORY/$IMAGE_NAME"
