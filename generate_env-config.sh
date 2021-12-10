#!/bin/bash
########################################
# Create a file based on the environment variables
# given by the dockerc run -e parameter
########################################
cat <<EOF
# cloudant
CLOUDANT_USERNAME="${CLOUDANT_USERNAME}"
CLOUDANT_PASSWORD="${CLOUDANT_PASSWORD}"
CLOUDANT_URL="${CLOUDANT_URL}"
CLOUDANT_PORT="${CLOUDANT_PORT}"
CLOUDANT_NAME="${CLOUDANT_NAME}"
# application
VEND_USAGE="${VEND_USAGE}"
USER="${USER}"
USER_PASSWORD="${USERPASSWORD}"
ADMINUSER="${ADMINUSER}"
ADMINUSER_PASSWORD="${ADMINUSERPASSWORD}"
# server
PORT=8080
EOF
