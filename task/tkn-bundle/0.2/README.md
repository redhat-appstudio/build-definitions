# tkn-bundle - Tekton Task to push a Tekton Bundle to an image registry

Tekton Task to build and push Tekton Bundles (OCI images) which contain
definitions of Tekton objects, most commonly Task and Pipeline objects.

Task finds all `*.yaml` or `*.yml` files within `CONTEXT`, packages and pushes
them as a Tekton Bundle to the image repository, name and tag specified by the
`IMAGE` parameter.

## Input Parameters

The task supports the following input parameters.

| Name            | Example                                           | Description                              |
|-----------------|---------------------------------------------------|------------------------------------------|
| SOURCE_ARTIFACT | $(tasks.clone-repository.results.SOURCE_ARTIFACT) | Source trusted artifact URI              |
| IMAGE           | registry.io/my-task:tag                           | Reference of the image task will produce |
| CONTEXT         | my-task/0.1                                       | Paths to include in the bundle image     |
| HOME            | /tekton/home                                      | Value for the HOME environment variable  |

`CONTEXT` can include multiple directories or files separated by comma or space.
Paths can be negated with exclamation mark to prevent inclusion of certain
directories or files. Negated paths are best placed at the end as they operate
on collected paths preceeding them. For example if `CONTEXT` is set to
`"0.1,!0.1/spec"` for this tree:

    .
    ├── 0.1
    │   ├── README.md
    │   ├── spec
    │   │   ├── spec_helper.sh
    │   │   ├── support
    │   │   │   ├── jq_matcher.sh
    │   │   │   └── task_run_subject.sh
    │   │   ├── test1.yaml
    │   │   ├── test2.yml
    │   │   ├── test3.yaml
    │   │   └── tkn-bundle_spec.sh
    │   ├── TESTING.md
    │   └── tkn-bundle.yaml
    └── OWNERS

Only the `0.1/tkn-bundle.yaml` file will be included in the bundle.

## Results

The task emits the following results.

| Name         | Example                 | Description                                                     |
|--------------|-------------------------|-----------------------------------------------------------------|
| IMAGE_URL    | registry.io/my-task:tag | Image repository where the built image was pushed with tag only |
| IMAGE_DIGEST | abc...                  | Digest of the image just built                                  |
