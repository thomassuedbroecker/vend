##############################
#           BUILD
##############################
FROM node:17-alpine as BUILD

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
RUN npm install && \
    mkdir modules

# Bundle app source
COPY ./modules/db-logging.js ./modules
COPY server.js ./
# COPY .env ./

##############################
#           PRODUCTION
##############################
FROM node:17-alpine

RUN apk --no-cache add curl
# Set permissions
WORKDIR /usr/src/app
RUN mkdir modules
COPY --from=BUILD /usr/src/app .
RUN chmod -R 777 /usr/src/app && \
    addgroup vending_group && \
    adduser -D vending_user -G vending_group

# Configure setup of the container
COPY ./docker_entrypoint.sh .
COPY ./generate_env-config.sh .

EXPOSE 8080
CMD ["/bin/sh","docker_entrypoint.sh"]