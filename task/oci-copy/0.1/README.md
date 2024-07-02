# oci-copy task

Given an `oci-copy.yaml` file in the user's source directory, the `oci-copy` task will copy content from arbitrary urls into the OCI registry.

It generates a limited SBOM and pushes that into the OCI registry alongside the image.

It is not to be considered safe for general use as it cannot provide a high degree of provenance for artficats and reports them only as "general" type artifacts in the purl spec it reports in the SBOM. Use only in limited situations.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|IMAGE|Reference of the image buildah will produce.||true|
|OCI_COPY_FILE|Path to the oci copy file.|./oci-copy.yaml|false|
|BEARER_TOKEN_SECRET_NAME|Name of a secret which will be made available to the build as an Authorization header|""|false|

## Results
|name|description|
|---|---|
|IMAGE_DIGEST|Digest of the image just built|
|IMAGE_URL|Image repository where the built image was pushed|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace containing the source code to copy.|false|

## oci-copy.yaml schema
JSON schema for the `oci-copy.yaml` file.

```json
{
    "type": "object",
    "required": ["artifacts", "artifact_type"],
    "properties": {
        "artifact_type": {
            "description": "Artifact type to be applied to the top-level OCI artifact, i.e. `application/x-mlmodel`",
            "type": "string"
        },
        "artifacts": {
            "type": "array",
            "items": {
                "type": "object",
                "required": ["source", "filename", "type", "sha256sum"],
                "properties": {
                    "source": {
                        "description": "URL of the artifact to copy",
                        "type": "string"
                    },
                    "filename": {
                        "description": "Filename that should be applied to the artifact in the OCI registry",
                        "type": "string"
                    },
                    "type": {
                        "description": "Media type that should be applied to the artifact in the OCI registry",
                        "type": "string"
                    },
                    "sha256sum": {
                        "description": "Digest of the artifact to be checked before copy",
                        "type": "string"
                    }
                }
            }
        }
    }
}
```
