# Build Definitions 
## Images shared across Tasks
|  Num   |  Image   | Task(s)  | Count   | 
| -------- | -------- | -------  | ------- | 
| 1 | quay.io/openshift-pipeline/openshift-pipelines-cli-tkn:5.0 | tkn-bundle | 1 | 
| 2 | quay.io/redhat-appstudio/build-definitions-source-image-build-utils | source-build | 1 | 
| 3 | quay.io/redhat-appstudio/buildah:v1.31.0 | build-image-manifest, buildah, buildah-10gb, buildah-20gb, buildah-24gb, buildah-6gb, buildah-8gb, buildah-remote | 8 | 
| 4 | quay.io/redhat-appstudio/cachi2:0.6.0 | buildah, buildah-10gb, buildah-20gb, buildah-24gb, buildah-6gb, buildah-8gb, buildah-remote, prefetch-dependencies | 8 | 
| 5 | quay.io/redhat-appstudio/clair-in-ci:v1 | clair-scan | 1 | 
| 6 | quay.io/redhat-appstudio/cosign:v2.1.1 | buildah, buildah-10gb, buildah-20gb, buildah-24gb, buildah-6gb, buildah-8gb, buildah-remote, buildah-rhtap, rpm-ostree, s2i-java, s2i-nodejs, show-sbom | 12 | 
| 7 | quay.io/redhat-appstudio/github-app-token | update-infra-deployments | 1 | 
| 8 | quay.io/redhat-appstudio/hacbs-jvm-build-request-processor:127ee0c223a2b56a9bd20a6f2eaeed3bd6015f77 | buildah, buildah-10gb, buildah-20gb, buildah-24gb, buildah-6gb, buildah-8gb, buildah-remote, s2i-java | 8 | 
| 9 | quay.io/redhat-appstudio/hacbs-test:latest | tkn-bundle | 1 | 
| 10 | quay.io/redhat-appstudio/hacbs-test:v1.2.1 | clair-scan, clamav-scan, deprecated-image-check, fbc-related-image-check, fbc-validation, inspect-image, sast-snyk-check, sbom-json-check, verify-signed-rpms | 9 | 
| 11 | quay.io/redhat-appstudio/multi-platform-runner:01c7670e81d5120347cf0ad13372742489985e5f | buildah-remote, rpm-ostree | 2 | 
| 12 | quay.io/redhat-appstudio/syft:v0.105.0 | buildah, buildah-10gb, buildah-20gb, buildah-24gb, buildah-6gb, buildah-8gb, buildah-remote, buildah-rhtap, rpm-ostree, s2i-java, s2i-nodejs | 11 | 
| 13 | quay.io/redhat-appstudio/task-toolset | update-deployment | 1 | 
| 14 | quay.io/redhat-appstudio/update-infra-deployments-task-script-image | update-infra-deployments | 1 | 
| 15 | quay.io/redhat-user-workloads/project-sagano-tenant/ostree-builder/ostree-builder-fedora-38:d124414a81d17f31b1d734236f55272a241703d7 | rpm-ostree | 1 | 
| 16 | quay.io/redhat-user-workloads/rhtap-o11y-tenant/tools/tools:b95417fbab81a012881b79fee82f187074248b84 | generate-odcs-compose, verify-signed-rpms | 2 | 
| 17 | registry.access.redhat.com/ubi8-minimal | acs-deploy-check, acs-image-check, acs-image-scan | 3 | 
| 18 | registry.access.redhat.com/ubi8/python-311 | buildah-rhtap | 1 | 
| 19 | registry.access.redhat.com/ubi9/buildah | buildah-rhtap | 1 | 
| 20 | registry.access.redhat.com/ubi9/buildah:9.1.0-5 | s2i-java, s2i-nodejs | 2 | 
| 21 | registry.access.redhat.com/ubi9/python-39:1-165 | buildah, buildah-10gb, buildah-20gb, buildah-24gb, buildah-6gb, buildah-8gb, buildah-remote, rpm-ostree, s2i-java, s2i-nodejs | 10 | 
| 22 | registry.access.redhat.com/ubi9/ubi-minimal:9.3-1552 | slack-webhook-notification, summary | 2 | 
| 23 | registry.redhat.io/ocp-tools-4-tech-preview/source-to-image-rhel8 | s2i-java, s2i-nodejs | 2 | 
| 24 | registry.redhat.io/openshift-pipelines/pipelines-git-init-rhel8:v1.8.2-8 | git-clone, update-infra-deployments | 2 | 
| 25 | registry.redhat.io/openshift4/ose-cli:4.13 | init | 1 | 
| 26 | registry.redhat.io/ubi9:9.2-696 | git-clone | 1 | 
## Tasks and Owners 
| Num |  Task  | Owner  |
|  ------- |  ------- | ------- |
|     1	| acs-deploy-check | No-Owners-File | 
|     2	| acs-image-check | No-Owners-File | 
|     3	| acs-image-scan | No-Owners-File | 
|     4	| build-image-manifest | Stonesoup Build Team | 
|     5	| buildah | Stonesoup Build Team | 
|     6	| buildah-10gb | Stonesoup Build Team | 
|     7	| buildah-20gb | Stonesoup Build Team | 
|     8	| buildah-24gb | Stonesoup Build Team | 
|     9	| buildah-6gb | Stonesoup Build Team | 
|    10	| buildah-8gb | Stonesoup Build Team | 
|    11	| buildah-remote | Stonesoup Build Team | 
|    12	| buildah-rhtap | Konflux Build Team | 
|    13	| clair-scan | Stonesoup Test Team | 
|    14	| clamav-scan | Stonesoup Test Team | 
|    15	| deprecated-image-check | Stonesoup Test Team | 
|    16	| fbc-related-image-check | Stonesoup Test Team | 
|    17	| fbc-validation | Stonesoup Test Team | 
|    18	| generate-odcs-compose | No-Owners-File | 
|    19	| git-clone | Stonesoup Build Team | 
|    20	| init | Stonesoup Build Team | 
|    21	| inspect-image | Stonesoup Test Team | 
|    22	| prefetch-dependencies | Stonesoup Build Team | 
|    23	| rpm-ostree | No-Owners-File | 
|    24	| s2i-java | Stonesoup Build Team | 
|    25	| s2i-nodejs | Stonesoup Build Team | 
|    26	| sast-snyk-check | Stonesoup Test Team | 
|    27	| sbom-json-check | Stonesoup Test Team | 
|    28	| show-sbom | Stonesoup Build Team | 
|    29	| slack-webhook-notification | Stonesoup Build Team | 
|    30	| source-build | Stonesoup Build Team | 
|    31	| summary | Stonesoup Build Team | 
|    32	| tkn-bundle | Stonesoup Enterprise Contract Team | 
|    33	| update-deployment | Stonesoup Build Team | 
|    34	| update-infra-deployments | Stonesoup Build Team | 
|    35	| verify-signed-rpms | No-Owners-File | 
