# Migration from 0.1 to 0.2

- **NOTE:** The `output` workspace will not contain any source files, only the
  trusted artifact containing the source files, to access the source files use
  the trusted artifacts[^1]
- The parameter `deleteExisting`,  used by `git-clone` task was removed. The
  source is no longer maintained in the workspace, all executions of the
  `git-clone` Task will be clean fetches.
- The parameters `subdirectory` used by `git-clone` task was removed. This
  parameter had a purpose when source was maintained in the workspace allowing
  for multiple `git-clone` Tasks to fetch to different directories.
- The parameter `gitInitImage` used by `git-clone` task was removed.

## Action from users

Update files in pull request created by RHTAP bot:
- Search for the task named `git-clone`
- Remove the `deleteExisting`, `subdirectory` and `gitInitImage` parameters from
  the `params` section

Any Tasks that require the source code now need be provided with the trusted
artifact URI from the result of the `git-clone` Task and include a step similar
to:

```yaml
params:
  # used to pass in the SOURCE_ARTIFACT result from the git-clone Task
  - name: SOURCE_ARTIFACT
    type: string
    description: The source trusted artifact URI
    default: ""

steps:
  - name: use-trusted-artifact
    image: quay.io/redhat-appstudio/build-trusted-artifacts:latest@sha256:2741aaaf0c06ab784dcab99545be615696d05a578bd4ae5a1b2d6e17e5c569c4
    args:
      - use
      - --store
      - $(workspaces.source.path) # references the same workspace provided to the git-clone task
      - $(params.SOURCE_ARTIFACT)=/var/source # adjust the destination (/var/source) as needed
```

And the `SOURCE_ARTIFACT` parameter needs to be passed via the Pipeline from the
`git-clone` Task with the same name. For example:

```yaml
tasks:
  - name: my-task
    params:
      - name: SOURCE_ARTIFACT
        value: $(tasks.clone-repository.results.SOURCE_ARTIFACT) # clone-repository is the name of the git-clone Task in the Pipeline
```

[^1]: https://github.com/redhat-appstudio/build-trusted-artifacts
