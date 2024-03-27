#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

spec_helper_configure() {
  import 'support/task_run_subject'
  import 'support/jq_matcher'
}
