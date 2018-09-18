#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student

switch_service_color 'mlbparks' "${GUID}" "${ORIGIN}"

switch_service_color 'nationalparks' "${GUID}" "${ORIGIN}"

switch_service_color 'parksmap' "${GUID}" "${ORIGIN}"

switch_service_color() {
  SERVICE=$1
  GUID=$2
  COLOR_RESPONSE=$3

  echo "app -> $1 / user ->  $2 / current color -> $3"

  if [[ $COLOR_RESPONSE = *"Blue"* ]]; then
    CURRENT='blue'
    TARGET='green'
  else
    CURRENT='green'
    TARGET='blue'
  fi

  SERVICE_CURRENT=${SERVICE}-${CURRENT}
  SERVICE_TARGET=${SERVICE}-${TARGET}

  echo "Setting ${SERVICE} Service in Parks Production Environment in project ${GUID}-prod from ${CURRENT} to ${TARGET}"

  oc scale dc/${SERVICE_TARGET} --replicas=1 -n "${GUID}-parks-prod"

  oc rollout latest dc/${SERVICE_TARGET} -n "${GUID}-parks-prod"

  oc patch service/${SERVICE} \
    -p "{\"metadata\":{\"labels\":{\"app\":\"${SERVICE_TARGET}\", \"template\":\"${SERVICE_TARGET}\"}}, \"spec\":{\"selector\":{\"app\":\"${SERVICE_TARGET}\", \"deploymentconfig\":\"${SERVICE_TARGET}\"}}}" \
    -n "${GUID}-parks-prod"

  oc scale dc/${SERVICE_CURRENT} --replicas=0 -n "${GUID}-parks-prod"
}