# buildah task

Buildah task builds source code into a container image and pushes the image into container registry using buildah tool.
In addition it generates a SBOM file, injects the SBOM file into final container image and pushes the SBOM file as separate image using cosign tool.
When [Java dependency rebuild](https://redhat-appstudio.github.io/docs.stonesoup.io/Documentation/main/cli/proc_enabled_java_dependencies.html) is enabled it triggers rebuilds of Java artifacts.
When prefetch-dependencies task was activated it is using its artifacts to run build in hermetic environment.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image buildah will produce.||true|
|BUILDER_IMAGE|Deprecated. Has no effect. Will be removed in the future.|""|false|
|DOCKERFILE|Path to the Dockerfile to build.|./Dockerfile|false|
|CONTEXT|Path to the directory to use as context.|.|false|
|TLSVERIFY|Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)|true|false|
|DOCKER_AUTH|unused, should be removed in next task version|""|false|
|HERMETIC|Determines if build will be executed without network access.|false|false|
|PREFETCH_INPUT|In case it is not empty, the prefetched content should be made available to the build.|""|false|
|IMAGE_EXPIRES_AFTER|Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively.|""|false|
|COMMIT_SHA|The image is built from this commit.|""|false|
|YUM_REPOS_D_SRC|Path in the git repository in which yum repository files are stored|repos.d|false|
|YUM_REPOS_D_FETCHED|Path in source workspace where dynamically-fetched repos are present|fetched.repos.d|false|
|YUM_REPOS_D_TARGET|Target path on the container in which yum repository files should be made available|/etc/yum.repos.d|false|
|TARGET_STAGE|Target stage in Dockerfile to build. If not specified, the Dockerfile is processed entirely to (and including) its last stage.|""|false|
|ENTITLEMENT_SECRET|Name of secret which contains the entitlement certificates|etc-pki-entitlement|false|
|BUILD_ARGS|Array of --build-arg values ("arg=value" strings)|[]|false|
|BUILD_ARGS_FILE|Path to a file with build arguments, see https://www.mankier.com/1/buildah-build#--build-arg-file|""|false|
|SQUASH|Squash all new and previous layers added as a part of this build, as per --squash|false|false|

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
