# oci-copy-oci-ta task

Given a file in the user's source directory, copy content from arbitrary urls into the OCI registry.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|BEARER_TOKEN_SECRET_NAME|Name of a secret which will be made available to the build as an Authorization header|""|false|
|IMAGE|Reference of the image we will push||true|
|OCI_COPY_FILE|Path to the oci copy file.|./oci-copy.yaml|false|
|SOURCE_ARTIFACT|The Trusted Artifact URI pointing to the artifact with the application source code.||true|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the artifact just pushed|
|IMAGE_URL|Repository where the artifact was pushed|

