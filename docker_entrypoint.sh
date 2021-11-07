#!/bin/bash

echo "*********************"
echo "** Verify enviroment values"
echo "*********************"

# cloudant
echo "${CLOUDANT_USERNAME}"
echo "${CLOUDANT_PASSWORD}"
echo "${CLOUDANT_URL}"
echo "${CLOUDANT_PORT}"
echo "${CLOUDANT_NAME}"
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
more .env

echo "*********************"
echo "** Start server"
echo "*********************"

npm start

