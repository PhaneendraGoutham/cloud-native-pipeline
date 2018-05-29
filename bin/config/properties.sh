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

pipeline_config_file=pipeline.yml
pipeline_credentials_file=credentials.yml
pipeline_parameters_file=parameters.yml

shared_pipeline_project=cloud-native-app-pipeline
shared_pipeline_project_dir=${workspace_dir}/${shared_pipeline_project}
shared_pipeline_config_file=${shared_pipeline_project_dir}/${pipeline_config_file}
shared_pipeline_parameters_file=${shared_pipeline_project_dir}/${pipeline_parameters_file}

ssh_key_size=4096
ssh_dir=/.ssh
