#!/bin/bash

set -eo pipefail

aws configure set s3.signature_version s3v4

main() {
  while [[ ! -f /opt/codedeploy-agent/ready ]]; do
    sleep 1
  done

  local release_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
  local config="$(cat ${release_dir}/config.json)"
  local release_bucket="$(echo $config | jq -r '.release_bucket')"

  local docker_image="$(echo $config | jq -r '.docker.image')"
  local docker_registry="$(echo $config | jq -r '.docker.registry')"
  local docker_login_email="$(echo $config | jq -r '.docker.login_email')"
  local docker_login_username="$(echo $config | jq -r '.docker.login_username')"
  local docker_compose_file="${release_dir}/production.yml"
  local ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  local deployment_id="$(cd ${release_dir}/../ && basename ${PWD})"
  local awslogs_stream="${ip}-${deployment_id}"

  # modify docker-compose production file with the image release
  sed -i -e "s/{{release}}/$(echo $docker_image | sed -e 's/[\/&]/\\&/g')/" $docker_compose_file

  # If salt is installed replace minion_id var in docker_compose_file
  if [[ $(which salt-call) ]]; then
    local minion_id="$(salt-call --out=json grains.get id | jq -r '.local')"
    sed -i -e "s/{{minion_id}}/$(echo $minion_id | sed -e 's/[\_\-\/&]/\\&/g')/" $docker_compose_file
  fi

  # login if we have credentials
  if [[ $docker_login_email && $docker_login_username && $docker_login_password ]]; then
    docker login --email="${docker_login_email}" --username="${docker_login_username}" --password="${docker_login_password}" $docker_registry
  fi

  docker pull $docker_image

  echo "Pulled new version of application from Docker repo"

  # If there is an application config on the releases s3 bucket. Download it
  local app_config_location="s3://${release_bucket}/config"

  if [[ $(aws s3 ls ${app_config_location}) ]]; then
    aws s3 cp ${app_config_location} /etc/codedeployapp/env.list
  fi
}

main "$@"
