# prefetch-dependencies task

Task that uses Cachi2 to prefetch build dependencies.
See docs at https://github.com/containerbuildsystem/cachi2#basic-usage.

## Parameters
|name|description|default value|required|
|---|---|---|---|
|input|Configures project packages that will have their dependencies prefetched.||true|
|hermetic|Controls if the dependencies will be prefetched.|false|false|

## Workspaces
|name|description|optional|
|---|---|---|
|source|Workspace with the source code, cachi2 artifacts will be stored on the workspace as well|false|
