
k8s_save_data() {
  local kind=$1
  local name=$2
  local namespace=${3:-}

  local namespace_opt=
  [[ -n $namespace ]] && namespace_opt="-n$namespace"

  local file=$( json_data_file cluster $kind $name )

  echo "Saving $kind $name $namespace_opt"
  oc get $namespace_opt $kind $name -o json > $file
}

_policy_config_from_configmap() {
  oc get configmap ec-policy -o go-template='{{index .data "policy.json"}}' 2>/dev/null
}

_default_policy_config() {
  echo '{"non_blocking_checks":["not_useful"]}'
}

# Splits the given string on '/' and returns the second part
cr_name() {
  echo "${1//*\//}"
}

# Checks if the given string has a '/' and if it does splits
# it on '/' and returns the "-n <first part>"
cr_namespace_argument() {
  if [[ "$1" != */* ]]; then
    return
  fi

  local namespace="${1//\/*/}"
  if [[ -n "${namespace}" ]]; then
    echo "-n ${namespace}"
  fi
}

# If given $1, looks up the ECP custom resource
save_policy_config() {
  local namespace_arg
  namespace_arg=$(cr_namespace_argument "${1:-}")
  local args
  args=(${namespace_arg} "$(cr_name "${1:-}")") # intentionally not quoting the $namespace_arg so it expands
  if ! non_blocking_data=$(kubectl get enterprisecontractpolicies.appstudio.redhat.com "${args[*]}" -o jsonpath='{.spec.exceptions.nonBlocking}'); then
    local namespace=${namespace_arg#-n }
    echo "ERROR: unable to find the ec-policy EnterpriseContractPolicy in namespace ${namespace:-$(kubectl config view --minify -o jsonpath='{..namespace}')}" 1>&2
    # TODO remove this condition once $1 is mandatory, i.e. we no longer
    # use the config map or the fallback policy below
    if [[ $# -gt 0 ]]; then # remove to fail unconditionally
      return 1
    fi
  else
    local non_blocking_data_file
    non_blocking_data_file="$( json_data_file config policy non_blocking_checks)"
    echo "$non_blocking_data" | jq > "${non_blocking_data_file}"
    return 0
  fi

  # TODO remove the below lines once the demos don't depend on this
  # Note: the namespace the task is running in needs to have the ec-policy ConfigMap
  { _policy_config_from_configmap || _default_policy_config ; } | jq > "$( json_data_file config policy )"
}
