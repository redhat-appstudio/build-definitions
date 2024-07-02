#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

eval "$(shellspec - -c) exit 1"

task_path=build-image-manifest.yaml

if [[ -f ../build-image-manifest.yaml ]]; then
    task_path="../build-image-manifest.yaml"
fi

# Extract the script so we can test it
script="$(mktemp --tmpdir script_XXXXXXXXXX.sh)"
chmod +x "${script}"
yq -r '.spec.steps[0].script' "${task_path}"  > "${script}"
trap 'rm -f "${script}"' EXIT

Describe "build-image-manifest task"
    Mock chown
        chown_args="$*"
        %preserve chown_args
    End

    Mock sed
        args=("$@")
        /usr/bin/sed "${args[@]::${#args[@]}-1}" "${registries_conf}"
    End

    Mock buildah
        echo buildah "$@" >&2
        args=("$@")
        if [[ "${args[1]}" == "push" ]]; then
            echo "sha256:manifest_digest" > image-digest
        fi
    End

    Mock results.IMAGE_DIGEST.path
        echo "${digest_file}"
    End

    Mock results.IMAGE_URL.path
        echo "${image_file}"
    End

    setup() {
        export registries_conf="$(mktemp --tmpdir registries_XXXXXXXXXX.conf)"
        echo 'short-name-mode = something' > "${registries_conf}"

        export digest_file="$(mktemp --tmpdir digest_XXXXXXXXXX.txt)"
        export image_file="$(mktemp --tmpdir digest_XXXXXXXXXX.txt)"

        export IMAGE=registry.io/repository/image:tag
        export TLSVERIFY=true
    }

    cleanup() {
        rm -f "${registries_conf}" "${digest_file}" "${image_file}" image-digest
    }

    BeforeEach setup
    AfterEach cleanup

    It "strips tags from image references"
        When call "${script}" registry.io/repository/image-amd64:tag@sha:abc
        The variable chown_args should eq "root:root /var/lib/containers"
        The contents of file "${registries_conf}" should eq 'short-name-mode = "disabled"'
        The output should eq 'Adding registry.io/repository/image-amd64@sha:abc
Pushing image to registry
sha256:manifest_digest
registry.io/repository/image:tag'
        The error should eq 'buildah manifest create registry.io/repository/image:tag
buildah manifest add registry.io/repository/image:tag docker://registry.io/repository/image-amd64@sha:abc
buildah manifest push --tls-verify=true --digestfile image-digest registry.io/repository/image:tag docker://registry.io/repository/image:tag'
    End

    It "supports digests following image references"
        When call "${script}" registry.io/repository/image-amd64 registry.io/repository/image-arm64:tag registry.io:12345/repository/image-ppc64le @sha:abc @sha:def @sha:ghi
        The variable chown_args should eq "root:root /var/lib/containers"
        The contents of file "${registries_conf}" should eq 'short-name-mode = "disabled"'
        The output should eq 'Adding registry.io/repository/image-amd64@sha:abc
Adding registry.io/repository/image-arm64@sha:def
Adding registry.io:12345/repository/image-ppc64le@sha:ghi
Pushing image to registry
sha256:manifest_digest
registry.io/repository/image:tag'
        The error should eq 'buildah manifest create registry.io/repository/image:tag
buildah manifest add registry.io/repository/image:tag docker://registry.io/repository/image-amd64@sha:abc
buildah manifest add registry.io/repository/image:tag docker://registry.io/repository/image-arm64@sha:def
buildah manifest add registry.io/repository/image:tag docker://registry.io:12345/repository/image-ppc64le@sha:ghi
buildah manifest push --tls-verify=true --digestfile image-digest registry.io/repository/image:tag docker://registry.io/repository/image:tag'
    End

    It "supports mixed image references"
        When call "${script}" registry.io/repository/image-amd64@sha:abc registry.io/repository/image-arm64 registry.io:12345/repository/image-ppc64le@sha:ghi registry.io:12345/repository/image-s390x @sha:def @sha:jkl
        The variable chown_args should eq "root:root /var/lib/containers"
        The contents of file "${registries_conf}" should eq 'short-name-mode = "disabled"'
        The output should eq 'Adding registry.io/repository/image-amd64@sha:abc
Adding registry.io/repository/image-arm64@sha:def
Adding registry.io:12345/repository/image-ppc64le@sha:ghi
Adding registry.io:12345/repository/image-s390x@sha:jkl
Pushing image to registry
sha256:manifest_digest
registry.io/repository/image:tag'
        The error should eq 'buildah manifest create registry.io/repository/image:tag
buildah manifest add registry.io/repository/image:tag docker://registry.io/repository/image-amd64@sha:abc
buildah manifest add registry.io/repository/image:tag docker://registry.io/repository/image-arm64@sha:def
buildah manifest add registry.io/repository/image:tag docker://registry.io:12345/repository/image-ppc64le@sha:ghi
buildah manifest add registry.io/repository/image:tag docker://registry.io:12345/repository/image-s390x@sha:jkl
buildah manifest push --tls-verify=true --digestfile image-digest registry.io/repository/image:tag docker://registry.io/repository/image:tag'
    End
End
