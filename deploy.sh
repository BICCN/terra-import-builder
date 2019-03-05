#!/usr/bin/env bash
set -euo pipefail

declare -r SCRIPT_DIR=$(cd $(dirname $0) && pwd)

# What we really want is to have a set of valid environment tokens
# with a "contains" check.
# As far as I can tell that isn't supported in bash.
# Instead we use the valid env strings as map keys with non-empty values.
# To check if a token is a valid env, we index into the map and assert
# that the result is non-empty.
declare -rA VALID_ENVS=([dev]=valid)

function check_usage () {
  if [[ $# -ne 1 ]]; then
    2>&1 echo Error: Incorrect number of arguments given, expected 1 '(environment)' but got $#
    exit 1
  elif [[ -z "${VALID_ENVS[$1]-}" ]]; then
    2>&1 echo Error: Invalid environment "'$1'", valid values are: ${!VALID_ENVS[@]}
    exit 1
  fi
}

function secret_path () {
    echo "secret/dsde/monster/$1/biccn/terra-import-builder/$2"
}

function deploy () {
    local -r env=$1
    local -r env_secrets=$(secret_path ${env} env)
    local -r account_secrets=$(secret_path ${env} service-account.json)

    gcloud --project=$(vault read -field=project ${env_secrets}) functions deploy \
        build-terra-import \
        --runtime=nodejs6 \
        --trigger-http \
        --entry-point=buildTerraImport \
        --set-env-vars TMP_BUCKET=$(vault read -field=bucket ${env_secrets}) \
        --source=${SCRIPT_DIR}/function \
        --service-account=$(vault read -field=client_email ${account_secrets})
}

main () {
    check_usage ${@}
    deploy $1
}

main ${@}
