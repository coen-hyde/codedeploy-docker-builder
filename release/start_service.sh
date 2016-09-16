#!/bin/bash

set -eo pipefail

main() {
  local release_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  local docker_compose_file="$release_dir/production.yml"

  export COMPOSE_PROJECT_NAME="codedeployapp"
  docker-compose -f $docker_compose_file up -d --force-recreate --no-color
}

main "$@"
