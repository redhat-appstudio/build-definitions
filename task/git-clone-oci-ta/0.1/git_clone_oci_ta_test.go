package git_clone_oci_ta_v01

import (
	"context"
	_ "embed"
	"fmt"
	"regexp"
	"testing"

	"github.com/stretchr/testify/require"
	tekton "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	meta "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/util/rand"

	"github.com/konflux-ci/build-definitions/internal/config"
	"github.com/konflux-ci/build-definitions/internal/kube"
	"github.com/konflux-ci/build-definitions/internal/tkn"
)

//go:embed git-clone-oci-ta.yaml
var taskDefinition []byte

var scheme = runtime.NewScheme()

func TestSimpleTest(t *testing.T) {
	ctx := context.Background()

	gitURL := "https://github.com/redhat-appstudio-qe/retrodep"
	gitRevision := "main"
	ociRepo := config.OCIRepo()
	gitOCIStorage := fmt.Sprintf("%s:git-%s", ociRepo, rand.String(5))

	taskSpec, err := tkn.TaskSpecFromDefinition(taskDefinition)
	require.NoError(t, err)

	taskRun := tekton.TaskRun{
		ObjectMeta: meta.ObjectMeta{
			GenerateName: "git-clone-oci-ta-v01-",
			Namespace:    config.KubeNamespace(),
		},
		Spec: tekton.TaskRunSpec{
			Params: []tekton.Param{
				{Name: "url", Value: *tekton.NewStructuredValues(gitURL)},
				{Name: "revision", Value: *tekton.NewStructuredValues(gitRevision)},
				{Name: "ociStorage", Value: *tekton.NewStructuredValues(gitOCIStorage)},
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

	commitResultFound := false
	urlResultFound := false
	sourceArtifactResultFound := false
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
		case "SOURCE_ARTIFACT":
			expected := regexp.QuoteMeta(fmt.Sprintf("oci:%s@sha256:", ociRepo))
			matched, err := regexp.MatchString(fmt.Sprintf("^%s[a-f0-9]{64}$", expected), result.Value.StringVal)
			require.NoError(t, err)
			require.True(t, matched)
			sourceArtifactResultFound = true
		}
	}
	require.True(t, commitResultFound)
	require.True(t, urlResultFound)
	require.True(t, sourceArtifactResultFound)
}
