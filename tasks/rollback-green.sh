#!/bin/bash
set -e -x -u

work_dir=$(dirname $0)
work_dir=$(dirname ${work_dir})
source ${work_dir}/shared/commons.sh

pcf_login \
    ${pcf_api_endpoint_uri} \
    ${pcf_org_name} \
    ${pcf_space_name} \
    ${pcf_username} \
    ${pcf_password}

pcf_rollback_green \
    ${pcf_app_name} \
    ${pcf_domain_name}
