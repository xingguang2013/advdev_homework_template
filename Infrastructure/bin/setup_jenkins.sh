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

oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi -n ${GUID}-jenkins

oc rollout pause dc jenkins -n ${GUID}-jenkins

oc set probe dc jenkins --readiness --initial-delay-seconds=180 --timeout-seconds=60 -n ${GUID}-jenkins

oc set probe dc/nexus3 --liveness --failure-threshold 3 --initial-delay-seconds 60 -- echo ok

oc rollout resume dc jenkins -n ${GUID}-jenkins

oc new-build --name=maven-slave-pod --dockerfile=$'FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9\n USER root\n RUN yum -y install skopeo apb && yum clean all\n USER 1001' -n ${GUID}-jenkins

while : ; do
  echo "Checking if Jenkins is Ready..."
   oc get pod -n ${GUID}-jenkins | grep -v "deploy\|build" | grep -q "1/1"
   [[ "$?" == "1" ]] || break
   echo "...no. Sleeping 10 seconds."
   sleep 10
done

oc tag maven-slave-pod:latest maven-slave-pod:v3.9 -n ${GUID}-jenkins

oc create -f ./Infrastructure/templates/mlbparks-pipeline.yaml -n ${GUID}-jenkins
oc create -f ./Infrastructure/templates/nationalparks-pipeline.yaml -n ${GUID}-jenkins
oc create -f ./Infrastructure/templates/parksmap-pipeline.yaml -n ${GUID}-jenkins

oc set env bc/mlbparks-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
oc set env bc/nationalparks-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
oc set env bc/parksmap-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins