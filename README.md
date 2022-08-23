### Overview

That branch of the project is used to support following blog posts:

- [Create an edge route for an example application on a Red Hat OpenShift Cluster on IBM Cloud](https://suedbroecker.net/2021/11/30/create-an-edge-route-for-an-example-application-on-a-red-hat-openshift-cluster-on-ibm-cloud/)

#### The `vend` application

Here is a short overview of the vend application example functionalities and how the example application is realized.

* What it does?


    * Uses basic authenication to secure the REST endpoint for an user and an admin
    * Provides `access codes` by REST endpoints to an user
    * Updates of `access codes` can be done with an admin user
    * You get `access codes` as an user
    * It logs parts of the REST API invokation in an [IBM Cloudant Database](https://www.ibm.com/cloud/cloudant?utm_content=SRCWW&p1=Search&p4=43700067990190230&p5=e&gclid=Cj0KCQjw9ZGYBhCEARIsAEUXITWyOiH3lCDB0wO9z2GlWWzB5tIC0mr4i9tpNFqadYBxLj8bNrHValsaAnL-EALw_wcB&gclsrc=aw.ds), if the database is configured.
    * It logs parts of the REST API invokation and startup procedure in a local log file.

* How the example application is realized?

    * Is a [Node.js](https://nodejs.org/en/) server application to provide access codes 
    * The application can be executed in a container
    * For deployments in an OpenShift cluster it has preconfigured
        
        * `Configmap` for application configuration
        * `Deployment` for the application
        * `Persistent volumes` for local log files
        * `Secrets` for user and admin passwords
        * `Kubernetes Service`
        * `OpenShift route` to access the application from the internet (HTTP only)


