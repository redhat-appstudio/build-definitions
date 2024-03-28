#!/bin/bash

set -e -o pipefail

QUAY_ORG=redhat-appstudio-tekton-catalog
# local dev build script
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORKDIR=$(mktemp -d --suffix "-$(basename "${BASH_SOURCE[0]}" .sh)")

tkn_bundle_push() {
    local status
    local retry=0
    local -r interval=${RETRY_INTERVAL:-5}
    local -r max_retries=5
    while true; do
        tkn bundle push "$@"
        status=$?
        if [ $status == 0 ]; then
            break
        fi
        ((retry+=1))
        if [ $retry -gt $max_retries ]; then
            return $status
        fi
        echo "Waiting for a while, then retry the tkn bundle push ..."
        sleep "$interval"
    done
}

# Helper function to record the image reference from the output of
# the "tkn bundle push" command into a given file.
# Params:
#   1. Image reference including the tag
#   2. Output file
# Returns the piped in standard input followed by a line containing the image
# reference including tag and digest
function save_ref() {
    local output
    output="$(< /dev/stdin)"
    echo "${output}"
    local digest
    digest="$(echo "${output}" | grep -Po '@\K(sha256:[a-f0-9]*)')"

    local tagRef
    tagRef="$1"
    local refFile
    refFile="$2"
    echo "${tagRef}@${digest}" >> "${refFile}"
    echo "Created:"
    echo "${tagRef}@${digest}"
}

if [[ $(uname) = Darwin ]]; then
    CSPLIT_CMD="gcsplit"
else
    CSPLIT_CMD="csplit"
fi

if [ -z "$MY_QUAY_USER" ]; then
    echo "MY_QUAY_USER is not set, skip this build."
    exit 0
fi
if [ -z "$BUILD_TAG" ]; then
    if [ "$MY_QUAY_USER" == "$QUAY_ORG" ]; then
        echo "'${QUAY_ORG}' repo is used, define BUILD_TAG"
        exit 1
    else
        # At the step of converting tasks to Tekton catalog, this is only
        # applied to non-task resources.
        BUILD_TAG=$(date +"%Y-%m-%d-%H%M%S")
        echo "BUILD_TAG is not defined, using $BUILD_TAG"
    fi
fi

# Specify TEST_REPO_NAME env var if you want to push all images to a single quay repository
# (This method is used in PR testing)
: "${TEST_REPO_NAME:=}"

APPSTUDIO_UTILS_IMG="quay.io/$MY_QUAY_USER/${TEST_REPO_NAME:-appstudio-utils}:${TEST_REPO_NAME:+build-definitions-utils-}$BUILD_TAG"

OUTPUT_TASK_BUNDLE_LIST="${OUTPUT_TASK_BUNDLE_LIST-${SCRIPTDIR}/../task-bundle-list}"
OUTPUT_PIPELINE_BUNDLE_LIST="${OUTPUT_PIPELINE_BUNDLE_LIST-${SCRIPTDIR}/../pipeline-bundle-list}"
rm -f "${OUTPUT_TASK_BUNDLE_LIST}" "${OUTPUT_PIPELINE_BUNDLE_LIST}"

# Build appstudio-utils image
if [ "$SKIP_BUILD" == "" ]; then
    echo "Using $MY_QUAY_USER to push results "
    docker build -t "$APPSTUDIO_UTILS_IMG" "$SCRIPTDIR/../appstudio-utils/"
    docker push "$APPSTUDIO_UTILS_IMG"
fi

generated_pipelines_dir=$(mktemp -d -p "$WORKDIR" pipelines.XXXXXXXX)
oc kustomize --output "$generated_pipelines_dir" pipelines/

# Generate YAML files separately since pipelines for core services have same .metadata.name.
core_services_pipelines_dir=$(mktemp -d -p "$WORKDIR" core-services-pipelines.XXXXXXXX)
oc kustomize --output "$core_services_pipelines_dir" pipelines/core-services/

# Build tasks
(
cd "$SCRIPTDIR/.."
find task/*/*/ -maxdepth 0 -type d | awk -F '/' '{ print $0, $2, $3 }' | \
while read -r task_dir task_name task_version
do
    prepared_task_file="${WORKDIR}/$task_name-${task_version}.yaml"
    if [ -f $task_dir/$task_name.yaml ]; then
        cp $task_dir/$task_name.yaml $prepared_task_file
        task_file_sha=$(git log -n 1 --pretty=format:%H -- $task_dir/$task_name.yaml)
    elif [ -f $task_dir/kustomization.yaml ]; then
        oc kustomize $task_dir > $prepared_task_file
        task_file_sha=$(sha256sum $prepared_task_file | awk '{print $1}')
    else
        echo Unknown task in $task_dir
        continue
    fi
    repository=${TEST_REPO_NAME:-task-${task_name}}
    tag=${TEST_REPO_NAME:+${task_name}-}${task_version}
    task_bundle=quay.io/$MY_QUAY_USER/${repository}:${tag}
    digest=$(curl -s https://quay.io/api/v1/repository/$MY_QUAY_USER/$repository/tag/?specificTag=${tag}-${task_file_sha} | yq '.tags[0].manifest_digest')
    if [ "$digest" == "null" ]; then
      output=$(tkn_bundle_push -f "$prepared_task_file" "$task_bundle" | save_ref "$task_bundle" "$OUTPUT_TASK_BUNDLE_LIST")
      echo "$output"
      task_bundle_with_digest="${output##*$'\n'}"

      # copy task to new tag pointing to commit where the file was changed lastly, so that image persists
      # even when original tag is updated
      skopeo copy "docker://${task_bundle}" "docker://${task_bundle}-${task_file_sha}"
    else
      task_bundle_with_digest=${task_bundle}@${digest}
    fi
    # version placeholder is removed naturally by the substitution.
    real_task_name=$(yq e '.metadata.name' "$prepared_task_file")
    sub_expr_1="
        (.spec.tasks[].taskRef | select(.name == \"${real_task_name}\" and .version == \"${task_version}\" ))
        |= {\"resolver\": \"bundles\", \"params\": [ { \"name\": \"name\", \"value\": \"${real_task_name}\" } , { \"name\": \"bundle\", \"value\": \"${task_bundle_with_digest}\" }, { \"name\": \"kind\", \"value\": \"task\" }] }
    "
    sub_expr_2="
        (.spec.finally[].taskRef | select(.name == \"${real_task_name}\" and .version == \"${task_version}\" ))
        |= {\"resolver\": \"bundles\", \"params\": [ { \"name\": \"name\", \"value\": \"${real_task_name}\" } , { \"name\": \"bundle\", \"value\": \"${task_bundle_with_digest}\" },{ \"name\": \"kind\", \"value\": \"task\" }] }
    "
    for filename in "$generated_pipelines_dir"/*.yaml "$core_services_pipelines_dir"/*.yaml
    do
        yq e "$sub_expr_1" -i "${filename}"
        yq e "$sub_expr_2" -i "${filename}"
    done
done
)

# Used for build-definitions pull request CI only
if [ -n "$ENABLE_SOURCE_BUILD" ]; then
    for pipeline_yaml in "$generated_pipelines_dir"/*.yaml; do
        yq e '(.spec.params[] | select(.name == "build-source-image") | .default) = "true"' -i "$pipeline_yaml"
    done
fi

# Build Pipeline bundle with pipelines pointing to newly built task bundles
for pipeline_yaml in "$generated_pipelines_dir"/*.yaml "$core_services_pipelines_dir"/*.yaml
do
    pipeline_name=$(yq e '.metadata.name' "$pipeline_yaml")
    core_services_ci=$(yq e '.metadata.annotations."appstudio.openshift.io/core-services-ci" // ""' "$pipeline_yaml")
    if [ "$core_services_ci" == "1" ]; then
        pipeline_name="core-services-${pipeline_name}"
        BUILD_TAG=latest
    fi

    repository=${TEST_REPO_NAME:-pipeline-${pipeline_name}}
    tag=${TEST_REPO_NAME:+${pipeline_name}-}$BUILD_TAG
    pipeline_bundle=quay.io/${MY_QUAY_USER}/${repository}:${tag}

    tkn_bundle_push "$pipeline_bundle" -f "${pipeline_yaml}" | \
        save_ref "$pipeline_bundle" "$OUTPUT_PIPELINE_BUNDLE_LIST"

    [ "$pipeline_name" == "docker-build" ] && docker_pipeline_bundle=$pipeline_bundle
    [ "$pipeline_name" == "fbc-builder" ] && fbc_pipeline_bundle=$pipeline_bundle
    [ "$pipeline_name" == "nodejs-builder" ] && nodejs_pipeline_bundle=$pipeline_bundle
    [ "$pipeline_name" == "java-builder" ] && java_pipeline_bundle=$pipeline_bundle
    if [ "$SKIP_DEVEL_TAG" == "" ] && [ "$MY_QUAY_USER" == "$QUAY_ORG" ] && [ -z "$TEST_REPO_NAME" ]; then
        NEW_TAG="${pipeline_bundle%:*}:devel"
        skopeo copy "docker://${pipeline_bundle}" "docker://${NEW_TAG}"
    fi
done

if [ "$SKIP_INSTALL" == "" ]; then
    "$SCRIPTDIR/util-install-bundle.sh" "$docker_pipeline_bundle,$fbc_pipeline_bundle,$nodejs_pipeline_bundle,$java_pipeline_bundle" "$INSTALL_BUNDLE_NS"
fi
