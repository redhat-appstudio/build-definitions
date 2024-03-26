# gather-deploy-images task

Extract images from deployment YAML to pass to EC for validation

## Parameters
|name|description|default value|required|
|---|---|---|---|
|TARGET_BRANCH|If specified, will gather only the images that changed between the current revision and the target branch. Useful for pull requests. Note that the repository cloned on the source workspace must already contain the origin/$TARGET_BRANCH reference. |""|false|

## Results
|name|description|
|---|---|
|IMAGES_TO_VERIFY|The images to be verified, in a format compatible with https://github.com/redhat-appstudio/build-definitions/tree/main/task/verify-enterprise-contract/0.1. When there are no images to verify, this is an empty string. |

## Workspaces
|name|description|optional|
|---|---|---|
|source|Should contain a cloned gitops repo at the ./source subpath|false|
