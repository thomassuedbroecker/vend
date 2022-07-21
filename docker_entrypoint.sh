#!/bin/bash

echo "*********************"
echo "** Verify enviroment values"
echo "*********************"

# cloudant
echo "Cloudant username: ${CLOUDANT_USERNAME}"
echo "Cloudant password: ${CLOUDANT_PASSWORD}"
echo "Cloudant URL: ${CLOUDANT_URL}"
echo "Cloudant port: ${CLOUDANT_PORT}"
echo "Cloudant name: ${CLOUDANT_NAME}"
# application
echo "${VEND_USAGE}"
echo "${USER}"
echo "${USERPASSWORD}"
echo "${ADMINUSER}"
echo "${ADMINUSERPASSWORD}"

echo "*********************"
echo "** Create enviroment file "
echo "*********************"

"/bin/sh" ./generate_env-config.sh > ./.env
cat .env

echo "*********************"
echo "** Start server"
echo "*********************"

npm start

