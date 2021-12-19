#!/bin/bash

# **************** Global variables


# ***************** for your configuration

# *** IBM Cloud locations
export RESOURCE_GROUP=default
export REGION="us-south"
# *** VPC
export VPC_NAME="partner-verify"
# *** OpenShift
export OC_PROJECT="vend-sec"
# *** VSI
export VSI_NAME="partner-client-tsuedbro"

# ***************** don't change
# *** set rootfolder path
root_folder=$(cd $(dirname $0); cd ../../; pwd)
echo "Working path: [$root_folder]"
# *** Loadbalancer configuration
export APP_NAME=vend-sec
export VPC_ZONE=""
export TEMPLATE_PRIVATE_LOAD_BALANCER_CONFIG_FILE="vend-private-load-balancer-template.yaml"
export PRIVATE_LOAD_BALANCER_CONFIG_FILE="vend-private-load-balancer.yaml"
export TEMPLATE_NGINX_CONFIG_FILE=ngnix-template.conf
export NGINX_CONFIG_FILE=ngnix.conf
export LOADBALANCER_HOSTNAME=""

# *** VPC extract
export VPC_ID=""
export SUBNET_ID=""
export SUBNET_NAME=""
export DEFAULT_NETWORK_ACL_ID=""
export DEFAULT_ROUTING_TABLE_ID=""
export DEFAULT_SECURITY_GROUP_ID=""
export TMP_VPC_CONFIG=tmp-vpc-configuration.json
export TMP_SUBNETS=tmp-subnets.json
export TMP_ZONE=tmp-zone.json
export TMP_PUBLICGATEWAY=tmp-public-gateway.json

# **********************************************************************************
# Functions definition
# **********************************************************************************

function _out() {
  echo "$(date +'%F %H:%M:%S') $@"
}

function setupCLIenv() {
    echo "-> ------------------------------------------------------------"
    echo "-  Setup IBM Cloud environment"
    echo "-> ------------------------------------------------------------"

    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
}

function getVPCconfig() {
    echo "-> ------------------------------------------------------------"
    echo "- Get the configuration for the Virtual Private Cloud $VPC_NAME"
    echo "-> ------------------------------------------------------------"
    
    ibmcloud is vpc $VPC_NAME --show-attached --output JSON > $TMP_VPC_CONFIG
    VPC_ID=$(cat ./$TMP_VPC_CONFIG | jq '.vpc.id' | sed 's/"//g')
    echo "VPC ID : $VPC_ID"

    DEFAULT_NETWORK_ACL_ID=$(cat ./$TMP_VPC_CONFIG | jq '.vpc.default_network_acl.id' | sed 's/"//g')
    DEFAULT_ROUTING_TABLE_ID=$(cat ./$TMP_VPC_CONFIG | jq '.vpc.default_routing_table.id' | sed 's/"//g')
    DEFAULT_SECURITY_GROUP_ID=$(cat ./$TMP_VPC_CONFIG | jq '.vpc.default_security_group.id' | sed 's/"//g')
    FIRST_ZONE=$(cat ./$TMP_VPC_CONFIG | jq '.vpc.cse_source_ips[0].zone.name' | sed 's/"//g')
    SUBNET_ID=$(cat ./$TMP_VPC_CONFIG | jq '.subnets[0].id' | sed 's/"//g')
    SUBNET_NAME=$(cat ./$TMP_VPC_CONFIG | jq '.subnets[0].name' | sed 's/"//g')
    echo "- Network acl ID    : $DEFAULT_NETWORK_ACL_ID"
    echo "- Routing table ID  : $DEFAULT_ROUTING_TABLE_ID"
    echo "- Security group ID : $DEFAULT_SECURITY_GROUP_ID"
    echo "- Subnet ID         : $SUBNET_ID"
    echo "- Zone              : $FIRST_ZONE"
    VPC_ZONE=$FIRST_ZONE

    #ibmcloud is subnet $SUBNET_NAME --vpc $VPC_ID --output json > ./$TMP_SUBNETS
    rm -f $TMP_VPC_CONFIG   
}

function setOCProject () {
   echo "-> ------------------------------------------------------------"
   echo "- Set OpenShift project $OC_PROJECT"
   echo "-> ------------------------------------------------------------"
   oc project $OC_PROJECT
}

function preparePrivateLoadbalancerService () {
  echo "-> ------------------------------------------------------------"
  echo "- Prepare private load balancer service"
  echo "-> ------------------------------------------------------------"
  
  KEY_1_TO_REPLACE=APP_NAME
  KEY_2_TO_REPLACE=VPC_ZONE
  KEY_3_TO_REPLACE=SUBNET_ID

  sed "s+$KEY_1_TO_REPLACE+$APP_NAME+g;s+$KEY_2_TO_REPLACE+$VPC_ZONE+g;s+$KEY_3_TO_REPLACE+$SUBNET_ID+g" "${root_folder}/openshift/config/private-loadbalancer/$TEMPLATE_PRIVATE_LOAD_BALANCER_CONFIG_FILE" > ${root_folder}/openshift/config/private-loadbalancer/$PRIVATE_LOAD_BALANCER_CONFIG_FILE
}

createPrivateLoadbalancerService() {
   echo "-> ------------------------------------------------------------"
   echo "- Create private load balancer service"
   echo "-> ------------------------------------------------------------"
   
   oc apply -f ${root_folder}/openshift/config/private-loadbalancer/$PRIVATE_LOAD_BALANCER_CONFIG_FILE -n $OC_PROJECT
   oc describe svc "$APP_NAME-vpc-nlb-$VPC_ZONE" -n $OC_PROJECT
   LOADBALANCER_HOSTNAME=$(oc describe svc "$APP_NAME-vpc-nlb-$VPC_ZONE" -n $OC_PROJECT | grep 'LoadBalancer Ingress' | awk '{print $3;}')
   echo "$LOADBALANCER_HOSTNAME"
   
   STATUS=""
   array=("$LOADBALANCER_HOSTNAME")
   for i in "${array[@]}"
   do 
        echo ""
        echo "------------------------------------------------------------------------"
        echo "Check $i"
        while :
        do
            FIND=$i
            STATUS_CHECK=$(oc describe svc "$APP_NAME-vpc-nlb-$VPC_ZONE" -n $OC_PROJECT | grep 'LoadBalancer Ingress' | awk '{print $3;}')
            echo "Status: $STATUS_CHECK"
            if [ "$STATUS" != "$STATUS_CHECK" ]; then
                echo "$(date +'%F %H:%M:%S') Status: $FIND is Ready"
                echo "------------------------------------------------------------------------"
                break
            else
                echo "$(date +'%F %H:%M:%S') Status: $FIND($STATUS_CHECK)"
                echo "------------------------------------------------------------------------"
            fi
            sleep 5
        done
   done

   echo "-> ------------------------------------------------------------"
   echo "- Create customized ngnix.conf file"
   echo "-> ------------------------------------------------------------"  
   KEY_1_TO_REPLACE=LOADBALANCER_HOSTNAME
   sed "s+$KEY_1_TO_REPLACE+$LOADBALANCER_HOSTNAME+g" "${root_folder}/openshift/vsi-ngnix/$TEMPLATE_NGINX_CONFIG_FILE" > ${root_folder}/openshift/vsi-ngnix/$NGINX_CONFIG_FILE
}

function displayEndpoints () {
  echo "-> ------------------------------------------------------------"
  echo "- Display endpoints"
  echo "-> ------------------------------------------------------------"  
 
  echo "VPC($VPC_NAME) private load balancer endpoint: http://$LOADBALANCER_HOSTNAME:80"
  FLOATING_IP=$(ibmcloud is instances | grep "$VSI_NAME" | awk '{print $5;}')
  echo "VPC($VPC_NAME), VSI ($VSI_NAME) Ngnix load balancer endpoint: http://$FLOATING_IP/"
}

# **********************************************************************************
# Execution
# **********************************************************************************

setupCLIenv
echo "<-- PRESS ANY KEY"
read

getVPCconfig
echo "<-- PRESS ANY KEY"
read

setOCProject
echo "<-- PRESS ANY KEY"
read

preparePrivateLoadbalancerService
echo "<-- PRESS ANY KEY"
read

createPrivateLoadbalancerService
echo "<-- PRESS ANY KEY"
read

displayEndpoints
echo "<-- PRESS ANY KEY"
read