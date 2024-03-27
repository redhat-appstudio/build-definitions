# source-build task

Source image build.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BINARY_IMAGE|Binary image name from which to generate the source image name.||true|
|BASE_IMAGES|Base images used to build the binary image. Each image per line in the same order of FROM instructions specified in a multistage Dockerfile. Default to an empty string, which means to skip handling a base image.|""|false|

## Results
|name|description|
|---|---|
|SOURCE_ARTIFACT|Trusted artifact containing the source code|
|BUILD_RESULT|Build result.|
|SOURCE_IMAGE_URL|The source image url.|
|SOURCE_IMAGE_DIGEST|The source image digest.|

## Workspaces
|name|description|optional|
|---|---|---|
|workspace|The workspace where source code is included.|false|
