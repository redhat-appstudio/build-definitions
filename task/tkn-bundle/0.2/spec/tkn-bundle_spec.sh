#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

eval "$(shellspec - -c) exit 1"

Describe "tkn-bundle task"
  setup() {
    if ! command -v kubectl &> /dev/null; then
      echo "ERROR: Please install kubectl"
      return 1
    fi

    # Create Kind cluster if it doesn't exist already
    CLUSTER_NAME="test-tkn-bundle"
    if ! command -v kind &> /dev/null; then
      curl https://i.jpillora.com/kubernetes-sigs/kind | bash
      mv kind "$HOME/.local/bin"
    fi
    kind get clusters -q | grep -q "${CLUSTER_NAME}" || {
      cat <<EOF | kind create cluster -q --name="${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      extraArgs:
        "service-node-port-range": "1-65535"
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 5000
    hostPort: 5000
    listenAddress: 127.0.0.1
    protocol: TCP
EOF
} || { echo 'ERROR: Unable to create a kind cluster'; return 1; }
    kubectl cluster-info 2>&1 || { echo 'ERROR: Failed to access the cluster'; return 1; }

    # Install Tekton Pipeline, proceed with the rest of the test of the setup
    kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.50.3/release.yaml

    # Create the test namespace
    kubectl create namespace test --dry-run=client -o yaml | kubectl apply -f -
    kubectl config set-context --current --namespace=test
    while ! kubectl get serviceaccount default 2> /dev/null
    do
      sleep 1
    done

    # Create the tkn-bundle Task
    kubectl apply -f tkn-bundle.yaml

    # Copy the task's YAML file to the persistent volume mounted as workspace for
    # running the task via a setup Pod

    # Create the PersistentVolumeClaim
    echo 'apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: workspace-pvc
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Mi
' | kubectl apply -f -

    # Image to run the setup pod with, taken from the Task definition
    IMAGE="$(kubectl get task tkn-bundle -o=jsonpath='{.spec.steps[2].image}')"
    # Semi-random name for the setup Pod
    SETUP_POD="setup-$(date +%s)"
    # Run the pod with the volume mounted at /workspace, the container is blocking
    # until "/stop" file is created
    kubectl run "${SETUP_POD}" \
        --restart=Never \
        --image="${IMAGE}" \
        --override-type=json \
        --overrides='[
            {"op":"add","path":"/spec/containers/0/volumeMounts","value":[{"name":"workspace","mountPath":"/workspace"}]},
            {"op":"add","path":"/spec/volumes","value":[{"name":"workspace","persistentVolumeClaim":{"claimName":"workspace-pvc"}}]}]' \
        --command -- bash -c 'while [ ! -f /tmp/stop ]; do sleep 1; done'
    # Wait for the Pod to be ready
    kubectl wait --for=condition=Ready "pod/${SETUP_POD}" --timeout=3m

    # Clean the volume before proceeding
    kubectl exec "${SETUP_POD}" -- sh -c 'rm -rf /workspace/*'

    # Copy the files over
    setup_file() {
      source="$1"
      dest="$2"

      kubectl exec -i "${SETUP_POD}" -- sh -c "mkdir -p \"$(dirname "${dest}")\"; cat > ${dest}" < "${source}"
    }
    setup_file spec/test1.yaml /workspace/source/test1.yaml
    setup_file spec/test2.yml /workspace/source/test2.yml
    setup_file spec/test3.yaml /workspace/source/sub/test3.yaml

    # Trigger the termination and delete the Pod
    kubectl exec "${SETUP_POD}" -- touch /tmp/stop
    kubectl delete pod "${SETUP_POD}"

    # Name of the Job that will setup the trusted artifact
    SETUP_TA_JOB="setup-ta-$(date +%s)"
    # Trusted artifacts image, taken from the Task definition
    TA_IMAGE="$(kubectl get task tkn-bundle -o=jsonpath='{.spec.steps[0].image}')"
    kubectl create job "${SETUP_TA_JOB}" \
        --image="${TA_IMAGE}" \
        --dry-run=client \
        --output=yaml \
        -- sh -c "/usr/local/bin/entrypoint create --store /workspace /workspace/source-artifact=/workspace/source; cat /workspace/source-artifact" \
    | kubectl patch -f - --type=json --dry-run=client --output=yaml --patch='[
      {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"workspace","mountPath":"/workspace"}]},
      {"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"workspace","persistentVolumeClaim":{"claimName":"workspace-pvc"}}]}]' \
    | kubectl apply -f -
    # Wait for the job creating the trusted artifact to finish
    kubectl wait --for=condition=complete "job/${SETUP_TA_JOB}"
    # Grab the artifact uri from the logs
    SOURCE_ARTIFACT=$(kubectl logs "job/${SETUP_TA_JOB}" | tail -1)

    # Deploy an image registry and expose it via a Service
    kubectl create deployment registry --image=docker.io/registry:2.8.1 --port=5000 --dry-run=client -o yaml | kubectl apply -f -
    kubectl create service nodeport registry --tcp=5000:5000 --dry-run=client -o yaml | kubectl patch -f - --type json --dry-run=client -o yaml -p '[{"op": "add", "path": "/spec/ports/0/nodePort", "value":5000}]' | kubectl apply -f -
    kubectl wait deployment registry --for=condition=Available --timeout=3m

    # Finally wait for Tekton Pipeline to be available
    kubectl -n tekton-pipelines wait deployment -l "app.kubernetes.io/part-of=tekton-pipelines" --for=condition=Available --timeout=3m
  }
  BeforeAll 'setup'

  It 'creates Tekton bundles'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:tag -p SOURCE_ARTIFACT="${SOURCE_ARTIFACT}" --use-param-defaults --timeout 1m --showlog -w name=source,claimName=workspace-pvc
    The output should include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/bundle:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'creates Tekton bundles from specific context'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/sub:tag -p CONTEXT=sub -p SOURCE_ARTIFACT="${SOURCE_ARTIFACT}" --use-param-defaults --timeout 1m --showlog -w name=source,claimName=workspace-pvc
    The output should not include 'Added Task: test1 to image'
    The output should not include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/sub'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/sub:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'creates Tekton bundles when context points to a file'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/file:tag -p CONTEXT=test2.yml -p SOURCE_ARTIFACT="${SOURCE_ARTIFACT}" --use-param-defaults --timeout 1m --showlog -w name=source,claimName=workspace-pvc
    The output should not include 'Added Task: test1 to image'
    The output should not include 'Added Task: test3 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/file'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/file:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'creates Tekton bundles when context points to a file and a directory'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/mix:tag -p CONTEXT=test2.yml,sub -p SOURCE_ARTIFACT="${SOURCE_ARTIFACT}" --use-param-defaults --timeout 1m --showlog -w name=source,claimName=workspace-pvc
    The output should not include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/mix'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/mix:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'creates Tekton bundles when using negation'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/neg:tag -p CONTEXT=!sub -p SOURCE_ARTIFACT="${SOURCE_ARTIFACT}" --use-param-defaults --timeout 1m --showlog -w name=source,claimName=workspace-pvc
    The output should not include 'Added Task: test3 to image'
    The output should include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/neg'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/neg:tag\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/home\\z")'
  End

  It 'allows overriding HOME environment variable'
    When call tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:summer-home -p HOME=/tekton/summer-home -p SOURCE_ARTIFACT="${SOURCE_ARTIFACT}" --use-param-defaults --timeout 1m --showlog -w name=source,claimName=workspace-pvc
    The output should include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_DIGEST").value | test("\\Asha256:[a-z0-9]+\\z")'
    The taskrun should jq '.status.results[] | select(.name=="IMAGE_URL").value | test("\\Aregistry:5000/bundle:summer-home\\z")'
    The taskrun should jq '.status.taskSpec.stepTemplate.env[] | select(.name == "HOME").value | test("\\A/tekton/summer-home\\z")'
  End

  It 'allows overriding the bundle step image'
    build_and_inspect() {
      tkn task start tkn-bundle -p IMAGE=registry:5000/bundle:replaced-image -p STEPS_IMAGE=registry.io/repository/replaced:latest -p SOURCE_ARTIFACT="${SOURCE_ARTIFACT}" --use-param-defaults --timeout 1m --showlog -w name=source,claimName=workspace-pvc
      tkn bundle list -o=go-template --template '{{range .spec.steps}}{{printf "%s\n" .image}}{{end}}' localhost:5000/bundle:replaced-image
    }

    When call build_and_inspect
    The output should include 'Added Task: test1 to image'
    The output should include 'Added Task: test2 to image'
    The output should include 'Added Task: test3 to image'
    The output should include 'Pushed Tekton Bundle to registry:5000/bundle'
    The output should include 'registry.io/repository/replaced:latest
registry.io/repository/replaced:latest
registry.io/repository/replaced:latest'
    The output should not include 'ubuntu'
    The stderr should include "*Warning*: This is an experimental command, it's usage and behavior can change in the next release(s)"
  End
End
