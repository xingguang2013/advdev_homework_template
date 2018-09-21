#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

oc policy add-role-to-user view --serviceaccount=default -n ${GUID}-parks-dev

oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n ${GUID}-parks-dev

echo "===================[new-app mongodb]====================================="
oc new-app -e MONGODB_USER=mongodb -e MONGODB_PASSWORD=mongodb -e MONGODB_DATABASE=mongodb -e MONGODB_ADMIN_PASSWORD=mongodb --name=mongodb registry.access.redhat.com/rhscl/mongodb-34-rhel7:latest -n ${GUID}-parks-dev


echo "===================[new-build mlbparks]=================================="
oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev

echo "===================[new-app mlbparks]===================================="
oc new-app ${GUID}-parks-dev/mlbparks:latest --name=mlbparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

echo "===================[create-configmap mlbparks-config]===================="
oc create configmap mlbparks-config --from-literal="APPNAME=MLB Parks (Dev)" \
    --from-literal="DB_HOST=mongodb" \
    --from-literal="DB_PORT=27017" \
    --from-literal="DB_USERNAME=mongodb" \
    --from-literal="DB_PASSWORD=mongodb" \
    --from-literal="DB_NAME=mongodb" \
    -n ${GUID}-parks-dev

echo "===================[set env mlbparks-config]============================="
oc set env dc/mlbparks --from=configmap/mlbparks-config -n ${GUID}-parks-dev

oc set triggers dc/mlbparks --remove-all -n ${GUID}-parks-dev

oc set probe dc/mlbparks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/mlbparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc expose dc mlbparks --port 8080 -n ${GUID}-parks-dev
oc expose svc mlbparks --labels="type=parksmap-backend" -n ${GUID}-parks-dev


echo "===================[new-build nationalparks]============================="
oc new-build --binary=true --name="nationalparks" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev

echo "===================[new-app nationalparks]==============================="
oc new-app ${GUID}-parks-dev/nationalparks:latest --name=nationalparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

echo "===================[create-configmap ationalparks-config]================"
oc create configmap nationalparks-config --from-literal="APPNAME=National Parks (Dev)" \
    --from-literal="DB_HOST=mongodb" \
    --from-literal="DB_PORT=27017" \
    --from-literal="DB_USERNAME=mongodb" \
    --from-literal="DB_PASSWORD=mongodb" \
    --from-literal="DB_NAME=mongodb" \
    -n ${GUID}-parks-dev
    
echo "===================[set env nationalparks-config]========================"
oc set env dc/nationalparks --from=configmap/nationalparks-config -n ${GUID}-parks-dev

oc set triggers dc/nationalparks --remove-all -n ${GUID}-parks-dev

oc set probe dc/nationalparks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/nationalparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc expose dc nationalparks --port 8080 -n ${GUID}-parks-dev

oc expose svc nationalparks --labels="type=parksmap-backend" -n ${GUID}-parks-dev


echo "===================[new-build parksmap]=================================="
oc new-build --binary=true --name="parksmap" redhat-openjdk18-openshift:1.2 -n ${GUID}-parks-dev

echo "===================[new-app parksmap]===================================="
oc new-app ${GUID}-parks-dev/parksmap:latest --name=parksmap --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev

echo "===================[create-configmap parksmap-config]===================="
oc create configmap parksmap-config --from-literal="APPNAME=ParksMap (Dev)" -n ${GUID}-parks-dev

echo "===================[set env parksmap-config]============================="
oc set env dc/parksmap --from=configmap/parksmap-config -n ${GUID}-parks-dev

oc set triggers dc/parksmap --remove-all -n ${GUID}-parks-dev

oc set probe dc/parksmap --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/parksmap --readiness --failure-threshold 5 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev

oc expose dc parksmap --port 8080 -n ${GUID}-parks-dev

oc expose svc parksmap -n ${GUID}-parks-dev