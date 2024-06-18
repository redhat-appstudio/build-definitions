package git_clone_v01

import (
	"context"
	_ "embed"
	"fmt"
	"regexp"
	"testing"

	"github.com/konflux-ci/build-definitions/internal/config"
	"github.com/konflux-ci/build-definitions/internal/kube"
	"github.com/konflux-ci/build-definitions/internal/tkn"
	"github.com/stretchr/testify/require"
	tekton "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	core "k8s.io/api/core/v1"
	meta "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

//go:embed git-clone.yaml
var taskDefinition []byte

var scheme = runtime.NewScheme()

func TestSimpleTest(t *testing.T) {
	ctx := context.Background()

	gitURL := "https://github.com/redhat-appstudio-qe/retrodep"
	gitRevision := "main"

	taskSpec, err := tkn.TaskSpecFromDefinition(taskDefinition)
	require.NoError(t, err)

	taskRun := tekton.TaskRun{
		ObjectMeta: meta.ObjectMeta{
			GenerateName: "git-clone-v01-",
			Namespace:    config.KubeNamespace(),
		},
		Spec: tekton.TaskRunSpec{
			Params: []tekton.Param{
				{Name: "url", Value: *tekton.NewStructuredValues(gitURL)},
				{Name: "revision", Value: *tekton.NewStructuredValues(gitRevision)},
			},
			TaskSpec: taskSpec,
			Workspaces: []tekton.WorkspaceBinding{
				{
					Name:     "output",
					EmptyDir: &core.EmptyDirVolumeSource{},
				},
			},
		},
	}

	k, err := kube.NewClient()
	require.NoError(t, err)

	require.NoError(t, k.Create(ctx, &taskRun))
	defer k.Delete(ctx, &taskRun)

	require.NoError(t, tkn.WaitForTaskRun(ctx, &taskRun, k, tkn.PollOptions{}))

	require.True(t, taskRun.IsSuccessful(), fmt.Sprintf("TaskRun was not successful: %#v", taskRun.Status.Conditions))

	commitResultFound := false
	urlResultFound := false
	for _, result := range taskRun.Status.Results {
		switch result.Name {
		case "commit":
			matched, err := regexp.MatchString(`^[a-f0-9]{40}$`, result.Value.StringVal)
			require.NoError(t, err)
			require.True(t, matched)
			commitResultFound = true
		case "url":
			require.Equal(t, result.Value.StringVal, gitURL)
			urlResultFound = true
		}
	}
	require.True(t, commitResultFound)
	require.True(t, urlResultFound)
}
