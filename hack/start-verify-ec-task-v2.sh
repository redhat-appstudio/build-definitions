#!/usr/bin/bash
#
# Rough hacking guide:
#
#  * Commit your changes as required. (No need to push to GitHub.)
#
#  * Push a new base image and new task bundles like this:
#      env MY_QUAY_USER=$USER BUILD_TAG=$(git rev-parse HEAD) ./build-and-push.sh
#
#    (Assumes you have the required repos created in quay.io, you're signed in there with podman,
#    and your quay.io username matches $USER)
#
#  * Create a Secret in the current namespace containing the cosign.pub key. This should be a
#    partial copy of the Secret tekton-chains/signing-secrets. Only the public key should be
#    included in this Secret. By default the name of the Secret is 'cosign-public-key', set
#    the PUBLIC_KEY_SECRET environment variable to use a different name. For example:
#    oc -n tekton-chains get secret signing-secrets -o json | jq '.data."cosign.pub" | @base64d' -r > cosign.pub
#    oc create secret generic cosign-public-key --from-file=cosign.pub
#
#  * Make sure you have an image that has already been signed by Chains.
#
#  * Run this script:
#      ./start-verify-ec-task-v2.sh <image-ref>
#    where <image-ref> is a valid image reference, e.g. quay.io/spam/bacon@sha256:...
#
set -euo pipefail

IMAGE_REF="$1"

PUBLIC_KEY_SECRET="${PUBLIC_KEY_SECRET:-cosign-public-key}"

NAMESPACE="$(oc project -q)"

#
# Create a simple Policy
#
oc apply -f - <<EOF
---
apiVersion: appstudio.redhat.com/v1alpha1
kind: EnterpriseContractPolicy
metadata:
  name: ec-policy
spec:
  description: Red Hat's enterprise requirements
  exceptions:
    nonBlocking:
    - not_useful
  sources:
  - git:
      repository: https://github.com/hacbs-contract/ec-policies
      revision: main
EOF

#
# Create an ApplicationSnapshot resource to ensure we're using correct format.
#
oc apply -f - <<EOF
---
apiVersion: appstudio.redhat.com/v1alpha1
kind: ApplicationSnapshot
metadata:
  name: demo-test
spec:
  application: my-app
  components:
    - containerImage: ${IMAGE_REF}
      name: my-component
EOF

#
# Retrieve the spec section of the ApplicationSnapshot. This is what the
# verify-enterprise-contract-v2 task uses.
#
IMAGES="$(oc get ApplicationSnapshot demo-test -o json | jq '.spec | tostring' -r)"

#
# Determine which bundle we should use
#
DEFAULT_BUNDLE=$(
  # ./build-and-push.sh creates this ConfigMap in the current project
  # and iiuc it overrides the default in `-n build-templates`
  oc get ConfigMap build-pipelines-defaults --output=jsonpath='{.data.default_build_bundle}' )
BUNDLE_NUMBER=3
USE_BUNDLE="$(
  echo "$DEFAULT_BUNDLE" | sed 's/build-templates-bundle/appstudio-tasks/' )-$BUNDLE_NUMBER"
echo "Using bundle $USE_BUNDLE for task"

TASK_RUN_NAME="verify-enterprise-contract-v2-$(openssl rand --hex 5)"

#
# Create the TaskRun
#
oc create -f - <<EOF
---
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: ${TASK_RUN_NAME}
spec:
  taskRef:
    name: verify-enterprise-contract-v2
    bundle: ${USE_BUNDLE}
  params:
    - name: IMAGES
      value: >
        ${IMAGES}

    - name: PUBLIC_KEY
      value: k8s://${NAMESPACE}/${PUBLIC_KEY_SECRET}

    # Set this so it works with a local instance of Rekor or the
    # official one.
    - name: SSL_CERT_DIR
      value: /var/run/secrets/kubernetes.io/serviceaccount

    # Uncomment if your cluster is using its own rekor instance
    #- name: REKOR_HOST
    #  value: https://rekor.apps-crc.testing

    # Modify these defaults as required
    #- name: STRICT
    #  value: "false"
    #- name: POLICY_CONFIGURATION
    #  value: ${NAMESPACE}/ec-policy

EOF

#
# Watch the TaskRun that was created
#
tkn tr logs -f $TASK_RUN_NAME
