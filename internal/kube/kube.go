package kube

import (
	_ "embed"

	tekton "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/client/config"
)

var scheme = runtime.NewScheme()

func NewClient() (client.Client, error) {
	config, err := config.GetConfig()
	if err != nil {
		return nil, err
	}

	client, err := client.New(config, client.Options{Scheme: scheme})
	if err != nil {
		return nil, err
	}

	return client, nil
}

func init() {
	tekton.AddToScheme(scheme)
}
