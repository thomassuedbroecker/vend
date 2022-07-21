#!/bin/bash

echo "*********************"
echo "** Verify enviroment values"
echo "*********************"

CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"

# cloudant
echo "***** cloudant"
echo "Cloudant username: ${CLOUDANT_USERNAME}"
echo "Cloudant password: ${CLOUDANT_PASSWORD}"
echo "Cloudant URL: ${CLOUDANT_URL}"
echo "Cloudant port: ${CLOUDANT_PORT}"
echo "Cloudant name: ${CLOUDANT_NAME}"
# application
echo "Vend usage: ${VEND_USAGE}"
echo "Vend user: ${USER}"
echo "Vend user password: ${USERPASSWORD}"
echo "Vend admin: ${ADMINUSER}"
echo "Vend admin password: ${ADMINUSERPASSWORD}"

echo "*********************"
echo "** Create enviroment file "
echo "*********************"

"/bin/sh" ./generate_env-config.sh > ./.env
cat .env

echo "*********************"
echo "** Start server"
echo "*********************"

ls 

node server.js
echo "npm start - doesn't work at the moment on openshift"

