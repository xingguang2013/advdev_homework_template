#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student

oc policy add-role-to-user admin system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-jenkins
oc policy add-role-to-user view system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-jenkins
oc policy add-role-to-user edit system:serviceaccount:gpte-jenkins:jenkins -n ${GUID}-jenkins

echo "===================[new-app jenkins-persistent]=========================="
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=4Gi --param VOLUME_CAPACITY=4Gi -n ${GUID}-jenkins

oc rollout pause dc jenkins -n ${GUID}-jenkins

echo "===================[set dc/jenkins readiness]============================"
oc set probe dc/jenkins --readiness --initial-delay-seconds=60 --timeout-seconds=60 -n ${GUID}-jenkins
echo "===================[set dc/jenkins liveness]============================="
oc set probe dc/jenkins --liveness --failure-threshold 3 --initial-delay-seconds 60 -- echo ok -n ${GUID}-jenkins

oc patch dc/jenkins -p '{"spec":{"strategy":{"recreateParams":{"timeoutSeconds":600}}}}' -n ${GUID}-jenkins

echo "===================[set dc/jenkins resources{cpu\memory}]================"
oc set resources dc/jenkins --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=1 -n ${GUID}-jenkins

oc rollout resume dc jenkins -n ${GUID}-jenkins

while : ; do
  echo "Checking Jenkins is Ready..."
   oc get pod -n ${GUID}-jenkins | grep -v "deploy\|build" | grep -q "1/1"
   [[ "$?" == "1" ]] || break
   echo "Sleeping 20 seconds for ${GUID}-jenkins."
   sleep 20
done

echo "Jenkins has been started successfully"

echo "===================[new-build jenkins-slave-pod]========================="
oc new-build --name=jenkins-slave-pod --dockerfile=$'FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9\n USER root\n RUN yum -y install skopeo apb && yum clean all\n USER 1001' -n ${GUID}-jenkins

echo "===================[tag jenkins-slave-pod -> jenkins-slave-pod:v3.9]====="
oc tag jenkins-slave-pod:latest jenkins-slave-pod:v3.9 -n ${GUID}-jenkins

echo "===================[new mlbparks-pipeline]==============================="
oc create -f ./Infrastructure/templates/mlbparks-pipeline.yaml -n ${GUID}-jenkins
echo "===================[new nationalparks-pipeline]=========================="
oc create -f ./Infrastructure/templates/nationalparks-pipeline.yaml -n ${GUID}-jenkins
echo "===================[new parksmap-pipeline]==============================="
oc create -f ./Infrastructure/templates/parksmap-pipeline.yaml -n ${GUID}-jenkins

echo "===================[set bc/mlbparks-pipeline env]========================"
oc set env bc/mlbparks-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
echo "===================[set bc/nationalparks-pipeline env]========================"
oc set env bc/nationalparks-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
echo "===================[set bc/parksmap-pipeline env]========================"
oc set env bc/parksmap-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins