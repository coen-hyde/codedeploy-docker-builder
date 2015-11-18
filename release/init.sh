#!/bin/bash

set -eo

main() {
  local docker_image=$(echo data.json | jq '.docker.image')
  local docker_registry=$(echo data.json | jq '.docker.registry')
  local docker_login_email=$(echo data.json | jq '.docker.login_email')
  local docker_login_password=$(echo data.json | jq '.docker.login_password')
  local docker_login_username=$(echo data.json | jq '.docker.login_username')

  local start_command="docker run --env-file /src/usr/codedeployapp/env.list $docker_image"

  docker login --email="${docker_login_email}" --username="${docker_login_password}" --password="${docker_login_username}" $docker_registry
  docker pull $docker_image

  cat <<EOF >/etc/init/codedeployapp
description "Code Deploy Application"
author "Me"
start on filesystem and started docker
stop on runlevel [!2345]
respawn
script
  $start_command
end script
EOF
}

main "$@"
