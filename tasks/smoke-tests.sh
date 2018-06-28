#!/bin/bash
set -e -x -u

work_dir=$(dirname $0)
source ${work_dir}/shared/commons.sh

cd source

pcf_app_name_blue=${pcf_app_name}-blue

version_check_endpoint_uri=$(replace_string ${version_check_endpoint_uri_template} "%s" ${pcf_app_name_blue})
version=$(get_version)

json=$(curl ${version_check_endpoint_uri} -k)
deployed_version=$(echo ${json} | jq -r '.build.version')

if [ "${deployed_version}" == "${version}" ] ; then
    status_string="passed"
else
    status_string="failed"
fi

if [ "$status_string" == "passed" ] ; then
    exit 0
else
    exit 1
fi

smoke_tests_task_script_path=$(get_cd_up_path ${smoke_tests_task_script})

if [ -d "${smoke_tests_task_script_path}" ]; then
    source ${smoke_tests_task_script_path}
fi

