#!/bin/bash
set -e -x -u

work_dir=$(dirname $0)
work_dir=$(dirname ${work_dir})
source ${work_dir}/shared/commons.sh

cd source

pcf_app_route_green=$(pcf_get_green_route_name ${pcf_app_name})

health_check_status=$(exec_smoke_test \
    "health" \
    ${health_check_endpoint_uri_template} \
    ".status" \
    "UP" \
    ${pcf_app_route_green} \
    ${pcf_domain_name})

if [ "${health_check_status}" == "failed" ] ; then
    exit 1
fi

version=$(get_version)
version_check_status=$(exec_smoke_test \
    "version" \
    ${version_check_endpoint_uri_template} \
    ".build.version" \
    ${version} \
    ${pcf_app_route_green} \
    ${pcf_domain_name})

if [ "${version_check_status}" == "failed" ] ; then
    exit 1
fi

smoke_tests_task_script_path=$(get_cd_up_path ${smoke_tests_task_script})${smoke_tests_task_script}

if [ -d "${smoke_tests_task_script_path}" ]; then
    source ${smoke_tests_task_script_path}
fi
