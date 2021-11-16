#!/bin/bash

# **************** Global variables
export ROOT_PATH=$(pwd)
export IMAGE_NAME=vend-simple:v1
export URL=quay.io
export REPOSITORY=tsuedbroecker

docker login quay.io
docker build -t "$URL/$REPOSITORY/$IMAGE_NAME" -f Dockerfile .
docker push "$URL/$REPOSITORY/$IMAGE_NAME"
