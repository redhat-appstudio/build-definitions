#!/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

ROOT="$(git rev-parse --show-toplevel)"

# Run tests only for changed
INCREMENTAL=${INCREMENTAL:-1}

readarray SPEC_DIRS < <(find "${ROOT}" -name spec -type d -print0)

REF=temp-$(openssl rand -base64 12)
git fetch origin "${GITHUB_BASE_REF:-main}:${REF}" >/dev/null 2>&1
function cleanup() {
    # shellcheck disable=SC2317
    git branch -D "${REF}" >/dev/null 2>&1 || true
}
trap cleanup EXIT
readarray CHANGED_FILES < <({ if [[ -n "${GITHUB_ACTIONS:-}" ]]; then git diff HEAD~1 --name-only; else git diff .."${REF}" --name-only; git status --porcelain=v1 | cut -c 4-; fi; }| uniq)

BIN_BASH=`which bash`
for CHANGED in "${CHANGED_FILES[@]}"; do
    CHANGED_DIR="${ROOT}/$(dirname "${CHANGED}")"
    for SPEC_DIR in "${SPEC_DIRS[@]}"; do
        # If the changed file is within the `spec` directory or the directory
        # above it
        if [[ "${CHANGED_DIR}" == "${SPEC_DIR}" || "${CHANGED_DIR}/spec" == "${SPEC_DIR}" ]]; then
            SPEC_DIRS=("${SPEC_DIRS[@]/${SPEC_DIR}}")
            [[ -n "${GITHUB_ACTIONS:-}" ]] && echo "::group::Shellspec test in ${SPEC_DIR}"
            echo -e "Detected changes in \033[1m${CHANGED_DIR}\033[0m, running tests"
            PARAMS=(--chdir "${SPEC_DIR}" --shell $BIN_BASH)
            [[ -n "${GITHUB_ACTIONS:-}" ]] && PARAMS+=(--format github -I "${ROOT}/hack/shellspec")
            if ! command -v shellspec &> /dev/null; then
                curl -fsSL https://git.io/shellspec | sh -s -- --yes
            fi
            shellspec "${PARAMS[@]}"
            [[ -n "${GITHUB_ACTIONS:-}" ]] && echo '::endgroup::'
        fi
    done
done
