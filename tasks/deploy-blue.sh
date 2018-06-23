#!/bin/bash
set -e -x -u

work_dir=$(dirname $0)
source ${work_dir}/shared/commons.sh

cd source

mkdir build
cp build.gradle build
cp gradle.properties build
cp manifest.yml build
cp settings.gradle build

group_id_path=$(get_group_id_path)
artifact_id=$(get_artifact_id)
version=$(get_version)

curl ${artifact_repo_uri}/${group_id_path}/${artifact_id}/${version}/${artifact_id}-${version}.jar -k -o ${artifact_id}.jar

set_manifest_properties ${artifact_id} ${pcf_app_name}

pcf_login \
    ${pcf_api_endpoint} \
    -o ${pcf_org_name} \
    -s ${pcf_space_name} \
    -u ${pcf_username} \
    -p ${pcf_password}

create_pcf_services_task_script_path="../../${create_pcf_services_task_script}"

if [ -d "${create_pcf_services_task_script_path}" ]; then
    source ${create_pcf_services_task_script_path}
fi

pcf_app_name_blue=${pcf_app_name}-blue
pcf_push ${pcf_app_name_blue}
