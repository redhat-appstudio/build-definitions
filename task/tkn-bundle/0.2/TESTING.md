# Testing tkn-bundle Tekton Task

Make sure you have shellspec installed[1]. The test setup script will bring up a
kind[2] cluster and installs Tekton Pipeline. The source is provided via the
`source-pvc` PersistantVolumeClaim and prepopulated with the test?.y*ml files in
order to not necesate the need for source checkout.

For second and subsequent invocations the setup is quicker as it only applies
any changes to already started and setup cluster. To delete the cluster and
start afresh run: `kind delete cluster --name=test-tkn-bundle`.

To run the tests run `shellspec` from this directory.

## Example of a testing setup and session

```shell
$ pwd
.../build-definitions/task/tkn-bundle/0.2
$ shellspec --jobs 5
Running: /bin/sh [bash 5.2.26(1)-release] {--jobs 5}
Kubernetes control plane is running at https://127.0.0.1:43139
CoreDNS is running at https://127.0.0.1:43139/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
namespace/tekton-pipelines unchanged
...
deployment.apps/tekton-pipelines-controller condition met
deployment.apps/tekton-pipelines-webhook condition met
.......

Finished in 64.83 seconds (user 10.45 seconds, sys 5.97 seconds)
7 examples, 0 failures
```

[1] https://shellspec.info/
[2] https://kind.sigs.k8s.io/
