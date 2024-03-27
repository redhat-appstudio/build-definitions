# Migration from 0.1 to 0.2

This version uses the trusted artifacts[^1] and requires that the
`SOURCE_ARTIFACT` parameter contains the URI to the previously created source
artifact, e.g. using the git-clone Task version 0.3 or newer.

Similarly the `CACHI2_ARTIFACT` can be provided containing the URI of the
artifact created by the prefetch-dependencies task version 0.2 or newer.

## Action from users

Update files in Pull-Request created by RHTAP bot:
- Search for the task named `build-container`
- if your pipeline includes a `prefetch-dependencies` task, as per default, add
  the `SOURCE_ARTIFACT` and `CACHI2_ARTIFACT` from the results of the
  `prefetch-dependencies` Task

```diff
 - name: build-container
   params:
+  - name: SOURCE_ARTIFACT
+    value: $(tasks.prefetch-dependencies.results.SOURCE_ARTIFACT)
+  - name: CACHI2_ARTIFACT
+    value: $(tasks.prefetch-dependencies.results.CACHI2_ARTIFACT)
```

- if your pipeline doesn't include the `prefetch-dependencies` task, provide the
  `SOURCE_ARTIFACT` parameter value from the result of the  `git-clone` Task.
  For example:

```diff
 - name: build-container
   params:
+  - name: SOURCE_ARTIFACT
+    value: $(tasks.clone-repository.results.SOURCE_ARTIFACT) # clone-repository is the name of the git-clone Task in the Pipeline
```



[^1]: https://github.com/redhat-appstudio/build-trusted-artifacts
