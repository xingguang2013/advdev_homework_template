#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
# while : ; do
#   echo "Checking if Nexus is Ready..."
#   oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
#   [[ "$?" == "1" ]] || break
#   echo "...no. Sleeping 10 seconds."
#   sleep 10
# done

# Ideally just calls a template
# oc new-app -f ../templates/nexus.yaml --param .....

# To be Implemented by Student

oc policy add-role-to-user admin system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-nexus
oc policy add-role-to-user view system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-nexus
oc policy add-role-to-user edit system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-nexus

echo "===================[new-app nexus]======================================="
oc process -f ./Infrastructure/templates/nexus-template.yaml -p GUID=${GUID} -n ${GUID}-nexus | oc create -f - -n ${GUID}-nexus

while : ; do
   echo "Checking Nexus is Ready..."
   oc get pod -n ${GUID}-nexus | grep -v "deploy\|build" | grep -q "1/1"
   [[ "$?" == "1" ]] || break
   echo "Sleeping 20 seconds for ${GUID}-nexus."
   sleep 20
done

echo "Nexus has been started successfully"

echo "===================[download setup_nexus3.sh]============================"
curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh

echo "===================[chmod +x setup_nexus3.sh]============================"
chmod +x setup_nexus3.sh

echo "===================[call setup_nexus3.sh]================================"
sh setup_nexus3.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}' -n ${GUID}-nexus)

echo "===================[rm setup_nexus3.sh]=================================="
rm setup_nexus3.sh