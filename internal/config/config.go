package config

import (
	"fmt"
	"os"
)

const (
	ociRepoEnvVar       = "TEST_OCI_REPO"
	kubeNamespaceEnvVar = "TEST_KUBE_NAMESPACE"
)

var (
	ociRepo       string
	kubeNamespace string
)

func OCIRepo() string {
	return ociRepo
}

func KubeNamespace() string {
	return kubeNamespace
}

func init() {
	ociRepo = os.Getenv(ociRepoEnvVar)
	if len(ociRepo) == 0 {
		panic(fmt.Errorf(
			"Use the %q environment variable to specify the OCI repo to be used by tests. "+
				"Make sure the ServiceAccount has a linked Secret with access to push content to the OCI repo. "+
				"See more info at https://tekton.dev/docs/pipelines/auth",
			ociRepoEnvVar))
	}

	kubeNamespace = os.Getenv(kubeNamespaceEnvVar)
	if len(kubeNamespace) == 0 {
		panic(fmt.Errorf(
			"Use the %q environment variable to specify the Kubernetes namespace to be used by tests",
			kubeNamespaceEnvVar))
	}
}
