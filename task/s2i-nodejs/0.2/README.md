# s2i-nodejs task

s2i-nodejs task builds source code into a container image and pushes the image into container registry using S2I and buildah tool.
In addition it generates a SBOM file, injects the SBOM file into final container image and pushes the SBOM file as separate image using cosign tool.


## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|Trusted artifact containing the source code||true|
|BASE_IMAGE|NodeJS builder image|registry.access.redhat.com/ubi9/nodejs-16:1-75.1669634583|false|
|PATH_CONTEXT|The location of the path to run s2i from.|.|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|IMAGE|Location of the repo where image has to be pushed||true|
|BUILDER_IMAGE|The location of the buildah builder image.|registry.access.redhat.com/ubi9/buildah:9.1.0-5@sha256:30eac1803d669d58c033838076a946156e49018e0d4f066d94896f0cc32030af|false|
|DOCKER_AUTH|unused, should be removed in next task version|""|false|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|MAVEN_MIRROR_URL|The base URL of a mirror used for retrieving artifacts|""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|
