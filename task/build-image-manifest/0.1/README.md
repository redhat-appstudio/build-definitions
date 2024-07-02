# build-image-manifest task

This task generates an image index from a collection of existing single platform images to create a multi-platform image.

## Parameters
| name                | description                                                                                                                                                        |default value|required|
|---------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|---|---|
| IMAGE               | Reference of the image buildah will produce.                                                                                                                       ||true|
| TLSVERIFY           | Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)                                                                                      |true|false|
| COMMIT_SHA          | The git commit sha that was used to produce the images                                                                                                             |""|false|
| IMAGES              | List of images that should be merged into a multi arch image                                                                                                       |false|false|
| IMAGE_EXPIRES_AFTER | Delete image tag after specified time. Empty means to keep the image tag. Time values could be something like 1h, 2d, 3w for hours, days, and weeks, respectively. |""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|

