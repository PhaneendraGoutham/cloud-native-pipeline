#!/usr/bin/env bash

workspace_dir=~/workspace

concourse_instance_name=opengood-io
concourse_uri=http://concourse.opengood.io:8080
default_concourse_team_name=main

default_pcf_api_endpoint=https://api.sys.cfapps.io
default_pcf_org_name=demo-gaig-org
default_pcf_space_name=development

github_api_uri=https://api.github.com
github_org=opengood-io
github_deploy_key_title=Concourse
github_repo_uri=git@github.com:opengood-io/repo.git
github_repo_default_branch=master

gpg_dir=~/.gnupg
gpg_absolute_dir=`eval "${gpg_dir}"`
gpg_key_type=default
gpg_key_length=2048
gpg_key_usage=encrypt,sign,auth
gpg_key_expire_date=365
gpg_key_server=https://keys.gnupg.net
gpg_key_ring_import_file=${gpg_dir}/gng-key.import
gpg_passphrase_file=${gpg_dir}/gpg-passphrase.txt
gpg_secret_keys_file=${gpg_absolute_dir}/secret-keys.gpg

pipeline_config_file=pipeline.yml
pipeline_credentials_file=credentials.yml
pipeline_parameters_file=parameters.yml

shared_pipeline_project=cloud-native-app-pipeline
shared_pipeline_project_dir=${workspace_dir}/${shared_pipeline_project}

app_pipeline_config_file=${shared_pipeline_project_dir}/app-pipeline.yml
app_pipeline_parameters_file=${shared_pipeline_project_dir}/app-parameters.yml

docker_pipeline_config_file=${shared_pipeline_project_dir}/docker-pipeline.yml
docker_pipeline_parameters_file=${shared_pipeline_project_dir}/docker-parameters.yml

ssh_dir=~/.ssh
ssh_key_size=4096
