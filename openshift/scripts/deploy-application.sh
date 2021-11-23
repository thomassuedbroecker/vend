#!/bin/bash

# **************** Global variables
root_folder=$(cd $(dirname $0); cd ../../; pwd)
echo "Working path: [$root_folder]"
# build config
export GIT_REPO="https://github.com/thomassuedbroecker/vend"
export TEMPLATE_BUILD_CONFIG_FILE="build-config-template.yaml"
export BUILD_CONFIG_FILE="build-config.yaml"
# image stream config
export IMAGESTREAM_CONFIG_FILE="imagestream-config.yaml"
export TEMPLATE_IMAGESTREAM_CONFIG_FILE="imagestream-config-template.yaml"
export IMAGESTREAM_JSON="imagestream.json"
export IMAGESTREAM_DOCKERIMAGEREFERENCE=""
# deployment config
export TEMPLATE_DEPLOYMENT_CONFIG_FILE="deployment-config-template.yaml"
export DEPOLYMENT_CONFIG_FILE="deployment-config.yaml"
# route config
export TEMPLATE_ROUTE_CONFIGE_FILE="route-config-template.yaml"
export ROUTE_CONFIGE_FILE="route-config.yaml"
# OpenShift
export OS_PROJECT="vend-image-stream"
export OS_BUILD="vend-build-config"
export OS_IMAGE_STREAM="vend-image-stream"
export OS_SERVICE="vend-service"

# **************** Load environments variables
export OS_DOMAIN=""

# change the standard output
exec 3>&1

# **********************************************************************************
# Functions definition
# **********************************************************************************

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function createPVCs () { 
  echo "-> create persistance volume claims"
  oc apply -f "${root_folder}/openshift/config/perstiant-volume-claim-config/pvcs.yaml"
}

function createSecrets () { 
  echo "-> create vend secrets"
  oc apply -f "${root_folder}/openshift/config/secrets/secrets-config.yaml"
}

function createConfigMap () { 
  echo "-> create vend configmap"
  oc apply -f "${root_folder}/openshift/config/configmaps/configmap.yaml"
}

function createAndApplyBuildConfig () {  
  echo "-> prepare image stream"
  KEY_TO_REPLACE=IMAGE_STREAM_1
  sed "s+$KEY_TO_REPLACE+$OS_IMAGE_STREAM+g" "${root_folder}/openshift/config/image-streams/$TEMPLATE_IMAGESTREAM_CONFIG_FILE" > ${root_folder}/openshift/config/image-streams/$IMAGESTREAM_CONFIG_FILE
 
  echo "-> create image stream" 
  oc apply -f "${root_folder}/openshift/config/image-streams/$IMAGESTREAM_CONFIG_FILE"
  oc describe imagestream
  #oc describe is/$OS_IMAGE_STREAM
  
  echo "-> prepare build config"
  KEY_TO_REPLACE=GIT_REPO_1
  sed "s+$KEY_TO_REPLACE+$GIT_REPO+g" "${root_folder}/openshift/config/build-config/$TEMPLATE_BUILD_CONFIG_FILE" > ${root_folder}/openshift/config/build-config/tmp.yaml
  KEY_TO_REPLACE=IMAGE_STREAM_1 
  sed "s+$KEY_TO_REPLACE+$OS_IMAGE_STREAM+g" "${root_folder}/openshift/config/build-config/tmp.yaml" > ${root_folder}/openshift/config/build-config/$BUILD_CONFIG_FILE
  rm -f ./tmp.yaml

  echo "-> create build config"
  oc apply -f "${root_folder}/openshift/config/build-config/$BUILD_CONFIG_FILE"
  
  echo "-> verify build config"
  oc describe bc/$OS_BUILD
  
  echo "-> start build"
  oc start-build $OS_BUILD
  
  echo "-> verify build logs"
  oc logs -f bc/$OS_BUILD
  
  echo "-> verify image stream"
  oc describe imagestream
  
  echo "-> extract image reference: $OS_IMAGE_STREAM"
  oc get imagestream "$OS_IMAGE_STREAM" -o json > ${root_folder}/openshift/config/image-streams/$IMAGESTREAM_JSON
  DOCKERIMAGEREFERENCE=$(cat ${root_folder}/openshift/config/image-streams/$IMAGESTREAM_JSON | jq '.status.dockerImageRepository' | sed 's/"//g')
  TAG=$(cat ${root_folder}/openshift/config/image-streams/$IMAGESTREAM_JSON | jq '.status.tags[].tag' | sed 's/"//g')
  rm -f ${root_folder}/openshift/config/image-streams/$IMAGESTREAM_JSON
  IMAGESTREAM_DOCKERIMAGEREFERENCE=$DOCKERIMAGEREFERENCE:$TAG
  echo "-> image reference : $IMAGESTREAM_DOCKERIMAGEREFERENCE"
}

function createDeployment () {
  echo "-> prepare deployment config"
  KEY_TO_REPLACE=CONTAINER_IMAGE_1
  echo "-> image: $IMAGESTREAM_DOCKERIMAGEREFERENCE"
  sed "s+$KEY_TO_REPLACE+$IMAGESTREAM_DOCKERIMAGEREFERENCE+g" "${root_folder}/openshift/config/deployments/$TEMPLATE_DEPLOYMENT_CONFIG_FILE" > ${root_folder}/openshift/config/deployments/$DEPOLYMENT_CONFIG_FILE
  
  echo "-> create deployment config"
  oc apply -f "${root_folder}/openshift/config/deployments/$DEPOLYMENT_CONFIG_FILE"
}

function createProject () {
  echo "-> delete project"
  oc delete project "$OS_PROJECT"
  echo "-> status project"
  oc status
  echo "-> verify project is deleted"
  echo "-> press return"
  read
  echo "-> create project"
  oc new-project "$OS_PROJECT"
}

function createService () {
  echo "-> create service config"
  oc apply -f "${root_folder}/openshift/config/services/service-config.yaml"
}

function createRoute () {
  echo "-> get ingress domain of the cluster"
  OS_DOMAIN=$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})
  echo "-> domain: $OS_DOMAIN"
  echo "-> prepare route"
  KEY_TO_REPLACE=OC_DOMAIN_1
  sed "s+$KEY_TO_REPLACE+$OS_DOMAIN+g" "${root_folder}/openshift/config/routes/$TEMPLATE_ROUTE_CONFIGE_FILE" > ${root_folder}/openshift/config/routes/tmp.yaml
  KEY_TO_REPLACE=OC_SERVICE_1
  sed "s+$KEY_TO_REPLACE+$OS_SERVICE+g" "${root_folder}/openshift/config/routes/tmp.yaml" > ${root_folder}/openshift/config/routes/$ROUTE_CONFIGE_FILE
  echo "-> create route"
  oc apply -f "${root_folder}/openshift/config/routes/$ROUTE_CONFIGE_FILE"
  rm -f ${root_folder}/openshift/config/routes/tmp.yaml
}

# **********************************************************************************
# Execution
# **********************************************************************************

echo "--------------------"
echo " 1. Create project"
echo "--------------------"
createProject

echo "--------------------"
echo " 2. Create persistant volume claims"
echo "--------------------"
createPVCs

echo "--------------------"
echo " 3. Create secrets"
echo "--------------------"
createSecrets

echo "--------------------"
echo " 4. Create configmap"
echo "--------------------"
createConfigMap

echo "--------------------"
echo " 5. Create and apply build"
echo "--------------------"
createAndApplyBuildConfig

echo "--------------------"
echo " 6. Create deployment"
echo "--------------------"
createDeployment

echo "--------------------"
echo " 7. Create service"
echo "--------------------"
createService

echo "--------------------"
echo " 8. Create route"
echo "--------------------"
createRoute