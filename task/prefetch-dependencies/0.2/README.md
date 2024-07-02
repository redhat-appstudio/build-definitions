# prefetch-dependencies task

Task that uses Cachi2 to prefetch build dependencies.
See docs at https://github.com/containerbuildsystem/cachi2#basic-usage.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|input|Configures project packages that will have their dependencies prefetched.||true|
|dev-package-managers|Enable in-development package managers. WARNING: the behavior may change at any time without notice. Use at your own risk. |false|false|
|log-level|Set cachi2 log level (debug, info, warning, error)|info|false|
|caTrustConfigMapName|The name of the ConfigMap to read CA bundle data from.|trusted-ca|false|
|caTrustConfigMapKey|The name of the key in the ConfigMap that contains the CA bundle data.|ca-bundle.crt|false|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace with the source code, cachi2 artifacts will be stored on the workspace as well|false|
|git-basic-auth|A Workspace containing a .gitconfig and .git-credentials file or username and password. These will be copied to the user's home before any cachi2 commands are run. Any other files in this Workspace are ignored. It is strongly recommended to bind a Secret to this Workspace over other volume types. |true|
