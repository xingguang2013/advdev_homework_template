#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student

oc policy add-role-to-user admin system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-sonarqube
oc policy add-role-to-user view system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-sonarqube
oc policy add-role-to-user edit system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-sonarqube

echo "===================[new-app sonarqube]==================================="
oc process -f ./Infrastructure/templates/sonarqube-template.yaml -p GUID=${GUID} -n ${GUID}-sonarqube | oc create -n ${GUID}-sonarqube -f -

while : ; do
   echo "Checking SonarQube is Ready..."
   oc get pod -n ${GUID}-sonarqube | grep -v "deploy\|build" | grep "sonarqube" | grep -q "1/1"
   [[ "$?" == "1" ]] || break
   echo "Sleeping 20 seconds for ${GUID}-sonarqube."
   sleep 20
done

echo "SonarQube has been started successfully"