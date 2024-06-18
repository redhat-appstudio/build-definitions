package init_v02

import (
	"context"
	_ "embed"
	"fmt"
	"testing"

	"github.com/stretchr/testify/require"
	tekton "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	meta "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"

	"github.com/konflux-ci/build-definitions/internal/config"
	"github.com/konflux-ci/build-definitions/internal/kube"
	"github.com/konflux-ci/build-definitions/internal/tkn"
)

//go:embed init.yaml
var taskDefinition []byte

var scheme = runtime.NewScheme()

func TestSimpleTest(t *testing.T) {
	ctx := context.Background()

	// For this test, any URL will do as long as there isn't an image at that location.
	imageURL := "registry.local/spam/bacon:latest"

	taskSpec, err := tkn.TaskSpecFromDefinition(taskDefinition)
	require.NoError(t, err)

	taskRun := tekton.TaskRun{
		ObjectMeta: meta.ObjectMeta{
			GenerateName: "init-v02-",
			Namespace:    config.KubeNamespace(),
		},
		Spec: tekton.TaskRunSpec{
			Params: []tekton.Param{
				{Name: "image-url", Value: *tekton.NewStructuredValues(imageURL)},
			},
			TaskSpec: taskSpec,
		},
	}

	k, err := kube.NewClient()
	require.NoError(t, err)

	require.NoError(t, k.Create(ctx, &taskRun))
	defer k.Delete(ctx, &taskRun)

	require.NoError(t, tkn.WaitForTaskRun(ctx, &taskRun, k, tkn.PollOptions{}))

	require.True(t, taskRun.IsSuccessful(), fmt.Sprintf("TaskRun was not successful: %#v", taskRun.Status.Conditions))

	buildResultFound := false
	for _, result := range taskRun.Status.Results {
		switch result.Name {
		case "build":
			require.Equal(t, result.Value.StringVal, "true")
			buildResultFound = true
		}
	}
	require.True(t, buildResultFound)
}
