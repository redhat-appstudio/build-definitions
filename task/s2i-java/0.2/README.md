# s2i-java task

s2i-java task builds source code into a container image and pushes the image into container registry using S2I and buildah tool.
In addition it generates a SBOM file, injects the SBOM file into final container image and pushes the SBOM file as separate image using cosign tool.
When [Java dependency rebuild](https://redhat-appstudio.github.io/docs.stonesoup.io/Documentation/main/cli/proc_enabled_java_dependencies.html) is enabled it triggers rebuilds of Java artifacts.


## Parameters
|name|description|default value|required|
|---|---|---|---|
|SOURCE_ARTIFACT|Trusted artifact containing the source code||true|
|BASE_IMAGE|Java builder image|registry.access.redhat.com/ubi9/openjdk-17:1.13-10.1669632202|false|
|PATH_CONTEXT|The location of the path to run s2i from|.|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|IMAGE|Location of the repo where image has to be pushed||true|
|BUILDER_IMAGE|The location of the buildah builder image.|registry.access.redhat.com/ubi9/buildah:9.1.0-5@sha256:30eac1803d669d58c033838076a946156e49018e0d4f066d94896f0cc32030af|false|
|DOCKER_AUTH|unused, should be removed in next task version|""|false|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|
|BASE_IMAGES_DIGESTS|Digests of the base images used for build|
|SBOM_JAVA_COMPONENTS_COUNT|The counting of Java components by publisher in JSON format|
|JAVA_COMMUNITY_DEPENDENCIES|The Java dependencies that came from community sources such as Maven central.|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to build.|false|
