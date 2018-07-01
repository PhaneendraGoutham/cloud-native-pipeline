#!/bin/bash
set -e -x -u

work_dir=$(dirname $0)
work_dir=$(dirname ${work_dir})
source ${work_dir}/shared/commons.sh

cd source

mkdir build
cp build.gradle build
cp gradle.properties build
cp manifest.yml build
cp settings.gradle build

group_id=$(get_group_id)
artifact_id=$(get_artifact_id)
version=$(get_version)

if [ -d "${project_dir}" ]; then
    cd ${project_dir}
    artifact_id=$(get_project_artifact_id)
    cd $(get_cd_up_path ${project_dir})
fi

cd build

download_artifact \
    ${artifact_repo_uri} \
    ${artifact_repo_name} \
    ${group_id} \
    ${artifact_id} \
    ${version}

pcf_login \
    ${pcf_api_endpoint_uri} \
    ${pcf_org_name} \
    ${pcf_space_name} \
    ${pcf_username} \
    ${pcf_password}

pcf_set_manifest_properties \
    ${pcf_app_name} \
    ${artifact_id}

create_pcf_services_task_script_path="$(get_cd_up_path ${create_pcf_services_task_script})${create_pcf_services_task_script}"
if [ -d "${create_pcf_services_task_script_path}" ]; then
    source ${create_pcf_services_task_script_path}
fi

pcf_deploy_green \
    ${pcf_app_name} \
    ${pcf_domain_name}
