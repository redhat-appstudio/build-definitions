package tkn

import (
	"context"
	_ "embed"
	"time"

	tekton "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1"
	"k8s.io/apimachinery/pkg/util/wait"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/yaml"
)

func TaskSpecFromDefinition(taskDefinition []byte) (*tekton.TaskSpec, error) {
	task := tekton.Task{}
	if err := yaml.Unmarshal(taskDefinition, &task); err != nil {
		return nil, err
	}
	return &task.Spec, nil
}

var (
	defaultPollInterval = time.Duration(3) * time.Second
	defaultPollTimeout  = time.Duration(3) * time.Minute
)

type PollOptions struct {
	Interval  time.Duration
	Timeout   time.Duration
	Immediate bool
}

func WaitForTaskRun(ctx context.Context, tr *tekton.TaskRun, k client.Client, opts PollOptions) error {
	if opts.Interval == time.Duration(0) {
		opts.Interval = defaultPollInterval
	}
	if opts.Timeout == time.Duration(0) {
		opts.Timeout = defaultPollTimeout
	}

	condition := func(context.Context) (bool, error) {
		if err := k.Get(ctx, client.ObjectKeyFromObject(tr), tr); err != nil {
			return false, err
		}
		return tr.IsDone(), nil
	}

	return wait.PollUntilContextTimeout(ctx, opts.Interval, opts.Timeout, opts.Immediate, condition)
}
