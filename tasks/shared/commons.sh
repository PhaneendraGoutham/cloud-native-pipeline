#!/bin/bash
set -e -x -u

function contains {
    local string="$1"
    local search_string="$2"

    if echo ${string} | grep -iqF "${search_string}"; then
        echo true
    else
        echo false
    fi
}

function ends_with {
    local string="$1"
    local character="$2"

    if [[ "${string: -1}" == "${character}" ]] ; then
        echo false
    else
        echo true
    fi
}

function format_gpg_key {
    local gpg_key="$1"

    local gpg_key_formatted=${gpg_key/-----BEGIN PGP PRIVATE KEY BLOCK-----/}
    gpg_key_formatted=${gpg_key_formatted/Version: GnuPG v2/}
    gpg_key_formatted=${gpg_key_formatted/-----END PGP PRIVATE KEY BLOCK-----/}
    gpg_key_formatted=`echo ${gpg_key_formatted} | sed 's/[ ]/\\\n/g'`

    local gpg_key_formatted_header="-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: GnuPG v2\\n\\n"
    local gpg_key_formatted_footer="\n-----END PGP PRIVATE KEY BLOCK-----"
    echo "${gpg_key_formatted_header}${gpg_key_formatted}${gpg_key_formatted_footer}"
}

function format_private_key {
    local private_key="$1"

    local key_formatted=${private_key/-----BEGIN RSA PRIVATE KEY-----/}
    key_formatted=${key_formatted/-----END RSA PRIVATE KEY-----/}
    key_formatted=`echo ${key_formatted} | sed 's/[ ]/\\\n/g'`

    local key_formatted_header="-----BEGIN RSA PRIVATE KEY-----\\n"
    local key_formatted_footer="\n-----END RSA PRIVATE KEY-----"
    echo "${key_formatted_header}${key_formatted}${key_formatted_footer}"
}

function configure_artifact_publishing {
    local artifact_repo_username="$1"
    local artifact_repo_password="$2"
    local artifact_repo_signing_key_id="$3"
    local artifact_repo_signing_key_passphrase="$4"
    local artifact_repo_signing_key_secret_keys="$5"

    echo -e $(format_gpg_key "${artifact_repo_signing_key_secret_keys}") > secret-keys.asc
    gpg2 --dearmor secret-keys.asc
    mv secret-keys.asc.gpg secret-keys.gpg

    echo "nexusUsername=${artifact_repo_username}" > gradle.properties
    echo "nexusPassword=${artifact_repo_password}" >> gradle.properties
    echo "signing.keyId=${artifact_repo_signing_key_id}" >> gradle.properties
    echo "signing.password=${artifact_repo_signing_key_passphrase}" >> gradle.properties
    echo "signing.secretKeyRingFile=${PWD}/secret-keys.gpg" >> gradle.properties
}

function get_artifact_file {
    local artifact_id="$1"
    local artifact_file=`find $(pwd) -name ${artifact_id}*jar`
    echo ${artifact_file}
}

function get_artifact_id {
    local artifact_id=`awk '/rootProject.name/{print $NF}' settings.gradle | sed s/\'//g`
    echo ${artifact_id}
}

function get_cd_up_path {
    local dir="$1"
    local character='/'

    if [[ $(ends_with "${dir}" "${character}") == "true" ]] ; then
        dir="${dir}/"
    fi

    local count=`echo "${dir}" | awk -F"${character}" '{print NF-1}'`

    local path=""
    for ((i = 1; i <= ${count}; i++));
    do
       path="${path}../"
    done
    echo ${path}
}

function get_current_date {
    local date=`TZ="America/New_York" date "+%Y-%m-%d"`
    echo ${date}
}

function get_current_timestamp {
    local timestamp=`TZ="America/New_York" date +"%F %T"`
    echo ${timestamp}
}

function get_group_id {
    local group_id=`awk '/group/{print $NF; exit}' build.gradle | sed s/\'//g`
    echo ${group_id}
}

function get_group_id_path {
    local group_id_path=`awk '/group/{print $NF; exit}' build.gradle | sed s/\'//g | tr "." "/"`
    echo ${group_id_path}
}

function get_json_content_type {
    local content_type="Content-Type:application/json"
    echo ${content_type}
}

function get_project_artifact_id {
    local artifact_id=`awk '/name/{print $NF; exit}' build.gradle | sed s/\'//g`
    echo ${artifact_id}
}

function get_release_notes {
   local version="$1"
   release_notes=`awk "/${version}/{flag=1;next}/## \[/{flag=0}flag" release-notes.md`
   echo ${release_notes}
}

function get_version {
    local version=`sed 's/version=//g' gradle.properties`
    echo ${version}
}

function get_version_from_artifact_file {
    local artifact_id="$1"
    version=`ls *.jar | sed "s/${artifact_id}-//g" | sed s/.jar//g`
    echo ${version}
}

function pcf_create_config_server {
    local pcf_config_server_name="$1"
    local pcf_config_server_git_repo_uri="$2"
    local pcf_config_server_git_repo_branch="$3"
    local pcf_config_server_git_repo_private_key="$4"
    local pcf_service_type=p-config-server
    local pcf_service_plan=standard

    private_key=$(format_private_key "${pcf_config_server_git_repo_private_key}")

    cf service ${pcf_config_server_name} || { \
    echo "Config Server ${pcf_config_server_name} not found. Creating new one..." >&2; \
    cf cs ${pcf_service_type} ${pcf_service_plan} ${pcf_config_server_name} -c "{\"git\": {\"uri\": \"${pcf_config_server_git_repo_uri}\", \"label\": \"${pcf_config_server_git_repo_branch}\", \"privateKey\": \"${private_key}\"}}"; \
    echo "Config Server ${pcf_config_server_name} created successfully! Waiting for service registry to initialize..." >&2
    until cf service ${pcf_config_server_name} | grep -m 1 "create succeeded"; do : ; done; \
    echo "Config Server ${pcf_config_server_name} initialization completed successfully!" >&2; }
}

function pcf_create_cups {
    local pcf_app_name="$1"
    local pcf_service_name="$2"
    local pcf_service_uri="$3"

    cf us ${pcf_app_name} ${pcf_service_name} || { echo "CUPS ${pcf_service_name} not found. Cannot unbind. Continuing on..." >&2; }
    cf ds ${pcf_service_name} -f || { echo "CUPS ${pcf_service_name} not found. Cannot delete. Continuing on..." >&2; }
    cf cups ${pcf_service_name} -p "{\"uri\":\"${pcf_service_uri}\"}"
    echo "CUPS ${pcf_service_name} create successfully!" >&2
}

function pcf_create_service {
    local pcf_app_name="$1"
    local pcf_service_name="$2"
    local pcf_service_type="$3"
    local pcf_service_plan="$4"

    cf us ${pcf_app_name} ${pcf_service_name} || { echo "Service ${pcf_service_name} not found. Cannot unbind. Continuing on..." >&2; }
    cf ds ${pcf_service_name} -f || { echo "Service ${pcf_service_name} not found. Cannot delete. Continuing on..." >&2; }
    cf cs ${pcf_service_type} ${pcf_service_plan} ${pcf_service_name}
    echo "Service ${pcf_service_name} create successfully!" >&2
}

function pcf_create_service_registry {
    local pcf_service_registry_name="$1"
    local pcf_service_type=p-service-registry
    local pcf_service_plan=standard

    cf service ${pcf_service_registry_name} || { \
    echo "Service Registry ${pcf_service_registry_name} not found. Creating new one..." >&2; \
    cf cs ${pcf_service_type} ${pcf_service_plan} ${pcf_service_registry_name}; \
    echo "Service Registry ${pcf_service_registry_name} created successfully! Waiting for service registry to initialize..." >&2
    until cf service ${pcf_service_registry_name} | grep -m 1 "create succeeded"; do : ; done; \
    echo "Service Registry ${pcf_service_registry_name} initialization completed successfully!" >&2; }
}

function pcf_login {
    local pcf_api_endpoint="$1"
    local pcf_org_name="$2"
    local pcf_space_name="$3"
    local pcf_username="$4"
    local pcf_password="$5"

    cf login \
        -a ${pcf_api_endpoint} \
        -o ${pcf_org_name} \
        -s ${pcf_space_name} \
        -u ${pcf_username} \
        -p ${pcf_password} \
        --skip-ssl-validation
}

function pcf_push_blue {
    local pcf_app_name="$1"
    cf push
}

function set_manifest_properties {
    local artifact_id="$1"
    local pcf_app_name="$2"

    sed -e "s/name\:.*/name\: ${pcf_app_name}/g" manifest.yml -i
    sed -e "s/path\:.*/path\: ${artifact_id}\.jar/g" manifest.yml -i
    echo "Manifest properties set successfully!" >&2
}

function replace_string {
    local string="$1"
    local search_string="$2"
    local replace_string="$3"
    local value=`echo ${string} | sed "s/${search_string}/${replace_string}/g"`
    echo ${value}
}

function to_lower_case {
    local string="$1"
    local value=`echo ${string} | awk '{print tolower($0)}'`
    echo ${value}
}

function to_title_case {
    local string="$1"
    local value=`echo ${string} | perl -ane 'foreach $wrd ( @F ) { print ucfirst($wrd)." "; } print "\n" ; '`
    echo ${value}
}

function to_upper_case {
    local string="$1"
    local value=`echo ${string} | awk '{print toupper($0)}'`
    echo ${value}
}
