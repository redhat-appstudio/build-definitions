#!/bin/bash

# Script for execution of the pipelines as Application Service

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

GITREPO=$1
PIPELINE_NAME=$2
shift 2
# the rest of the params are passed to tkn
TKN_PARAMS=("$@")

if [ -z "$GITREPO" ]; then
  echo Missing parameter Git URL to Build
  exit 1
fi
if [ -z "$PIPELINE_NAME" ]; then
  echo Missing parameter Pipeline name
  exit 1
fi

APPNAME=$(basename $GITREPO)
IMAGE_FULL_TAG=$(git ls-remote $GITREPO HEAD)
IMAGE_SHORT_TAG=${IMAGE_FULL_TAG:position:7}
BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S")
NS=$(oc config view --minify -o "jsonpath={..namespace}")

if [ -z "$MY_QUAY_USER" ]; then
  IMG=image-registry.openshift-image-registry.svc:5000/$NS/$APPNAME:$IMAGE_SHORT_TAG
  echo MY_QUAY_USER env variable is not set, pushing to $IMG
else
  if oc get secret redhat-appstudio-staginguser-pull-secret &>/dev/null; then
     # Ensure that the appstudio-pipeline service account has access to the secret. Although the
     # secret is mounted directly on the pipeline, Tekton Chains needs this linkage so
     # it can push the image signature and attestation to the same OCI repository.
     oc secrets link appstudio-pipeline redhat-appstudio-staginguser-pull-secret
  else
     echo "Secret redhat-appstudio-staginguser-pull-secret is not created, can be created by:"
     echo "Docker:"
     echo "  oc create secret docker-registry redhat-appstudio-staginguser-pull-secret --from-file=.dockerconfigjson=$HOME/.docker/config.json"
     echo "Podman:"
     echo "  oc create secret docker-registry redhat-appstudio-staginguser-pull-secret --from-file=.dockerconfigjson=${XDG_RUNTIME_DIR}/containers/auth.json"
     echo "(Note: it will upload all login credentials, make sure that you are not logged into sensitive registries, or create the particular secret manually!)"
     echo "and link it to the pipeline ServiceAccount:"
     echo "  oc secrets link appstudio-pipeline redhat-appstudio-staginguser-pull-secret"
     echo ""
  fi
  IMG=quay.io/$MY_QUAY_USER/$APPNAME:$IMAGE_SHORT_TAG
  echo Building $IMG
fi

if [ "$SKIP_CHECKS" == "1" ]; then
  SKIP_CHECKS_PARAM="-p skip-checks=true"
fi

tkn pipeline start $PIPELINE_NAME \
    -w name=workspace,volumeClaimTemplateFile=$SCRIPTDIR/test-build/workspace-template.yaml \
    $SKIP_CHECKS_PARAM \
    -p git-url=$GITREPO \
    -p output-image=$IMG \
    "${TKN_PARAMS[@]}" \
    --use-param-defaults

