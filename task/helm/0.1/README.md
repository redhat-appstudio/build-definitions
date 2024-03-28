# helm task

Testing out a task definition to build and push a helm chart

## Parameters
<!--|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image buildah will produce.||true|
|BUILDER_IMAGE|The location of the buildah builder image.|registry.access.redhat.com/ubi9/buildah:9.0.0-19@sha256:c8b1d312815452964885680fc5bc8d99b3bfe9b6961228c71a09c72ca8e915eb|false|
|DOCKERFILE|Path to the Dockerfile to build.|./Dockerfile|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|DOCKER_AUTH|unused, should be removed in next task version|""|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|PREFETCH_INPUT|In case it is not empty, the prefetched content should be made available to the build.|""|false|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|-->

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|
