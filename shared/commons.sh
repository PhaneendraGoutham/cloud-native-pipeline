#!/bin/bash

function configure_artifact_repo_publishing {
    local artifact_repo_username="$1"
    local artifact_repo_password="$2"
    local artifact_repo_signing_key_id="$3"
    local artifact_repo_signing_key_passphrase="$4"
    local artifact_repo_signing_key_secret_keys="$5"

    echo -e $(format_gpg_key "${artifact_repo_signing_key_secret_keys}") > secret-keys.asc
    gpg2 --dearmor secret-keys.asc
    mv secret-keys.asc.gpg secret-keys.gpg

    echo "Storing artifact publishing properties for Maven Central repo in gradle.properties..." &>2
    echo "nexusUsername=${artifact_repo_username}" > gradle.properties
    echo "nexusPassword=${artifact_repo_password}" >> gradle.properties
    echo "signing.keyId=${artifact_repo_signing_key_id}" >> gradle.properties
    echo "signing.password=${artifact_repo_signing_key_passphrase}" >> gradle.properties
    echo "signing.secretKeyRingFile=${PWD}/secret-keys.gpg" >> gradle.properties
}

function contains_string {
    local string="$1"
    local search_string="$2"

    if echo ${string} | grep -iqF "${search_string}"; then
        echo true
    else
        echo false
    fi
}

function create_github_repo_deploy_key {
    local github_api_uri="$1"
    local github_user="$2"
    local github_token="$3"
    local github_org="$4"
    local github_repo="$5"
    local github_deploy_key_title="$6"
    local github_deploy_key="$7"
    local github_deploy_key_read_only="$8"

    local json="{"
    json+="\"title\":\"${github_deploy_key_title}\","
    json+="\"key\":\"${github_deploy_key}\","
    json+="\"read_only\": ${github_deploy_key_read_only}"
    json+="}"

    echo "Creating GitHub deploy key for repo '${github_repo}'..." &>2
    curl -u "${github_user}:${github_token}" \
        -d "${json}" \
        -X POST \
        "${github_api_uri}/repos/${github_org}/${github_repo}/keys"
}

function delete_github_repo_deploy_key {
    local github_api_uri="$1"
    local github_user="$2"
    local github_token="$3"
    local github_org="$4"
    local github_repo="$5"
    local github_deploy_key_id="$6"

    echo "Creating GitHub deploy key for repo '${github_repo}'..." &>2
    curl -u "${github_user}:${github_token}" \
        -X DELETE \
        "${github_api_uri}/repos/${github_org}/${github_repo}/keys/${github_deploy_key_id}"
}

function download_artifact {
    local artifact_repo_uri="$1"
    local artifact_repo_name="$2"
    local group_id="$3"
    local artifact_id="$4"
    local version="$5"

    echo "Downloading artifact '${artifact_id}' from repo '${artifact_repo_uri}/${artifact_repo_name}'..." &>2
    curl -L "${artifact_repo_uri}/service/local/artifact/maven/redirect?r=${artifact_repo_name}&g=${group_id}&a=${artifact_id}&v=${version}" \
        -k -o ${artifact_id}.jar
}

function exec_smoke_test {
    local smoke_test_type="$1"
    local smoke_test_endpoint_uri_template="$2"
    local smoke_test_json_path="$3"
    local smoke_test_expected_value="$4"
    local pcf_app_name="$5"
    local pcf_domain_name="$6"

    local smoke_test_endpoint_uri=$(replace_string ${smoke_test_endpoint_uri_template} "app" ${pcf_app_name})
    smoke_test_endpoint_uri=$(replace_string ${smoke_test_endpoint_uri} "domain" ${pcf_domain_name})

    echo "Executing smoke test '${smoke_test_type}' to URI '${smoke_test_endpoint_uri}' expecting value '${smoke_test_expected_value}'..." &>2
    local json=$(curl ${smoke_test_endpoint_uri} -k)
    local smoke_test_actual_value=$(echo ${json} | jq -r ${smoke_test_json_path})
    echo "Received actual value from smoke test '${smoke_test_type}' '${smoke_test_actual_value}'" &>2

    if [ "${smoke_test_expected_value}" == "${smoke_test_actual_value}" ] ; then
        echo "Smoke test '${smoke_test_type}' PASSED!!!" &>2
        echo "passed"
    else
        echo "Smoke test '${smoke_test_type}' FAILED!" &>2
        echo "failed"
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

function format_rsa_key {
    local rsa_key="$1"

    local key_formatted=${rsa_key/-----BEGIN RSA PRIVATE KEY-----/}
    key_formatted=${key_formatted/-----END RSA PRIVATE KEY-----/}
    key_formatted=`echo ${key_formatted} | sed 's/[ ]/\\\n/g'`

    local key_formatted_header="-----BEGIN RSA PRIVATE KEY-----\\n"
    local key_formatted_footer="\n-----END RSA PRIVATE KEY-----"
    echo "${key_formatted_header}${key_formatted}${key_formatted_footer}"
}

function fly_login {
    local concourse_instance_name="$1"
    local concourse_uri="$2"
    local concourse_team_name="$3"
    local concourse_username="$4"
    local concourse_password="$5"

    echo "Logging into Concourse CI instance '${concourse_instance_name}' for team '${concourse_team_name}' via Fly CLI..." &>2
    local output=`fly -t ${concourse_instance_name} login \
        -c ${concourse_uri} \
        -n ${concourse_team_name} \
        -u ${concourse_username} \
        -p ${concourse_password} \
        -k`
    echo ${output}
}

function fly_set_pipeline {
    local concourse_instance_name="$1"
    local pipeline_name="$2"
    local project_pipeline_config_file="$3"
    local generated_pipeline_parameters_file="$4"

    echo "Setting pipeline '${pipeline_name}' in Concourse CI instance '${concourse_instance_name}' via Fly CLI..." &>2
    fly -t ${concourse_instance_name} set-pipeline \
        -p ${pipeline_name} \
        -c ${project_pipeline_config_file} \
        -l ${generated_pipeline_parameters_file} \
        -n

    fly -t ${concourse_instance_name} expose-pipeline \
        -p ${pipeline_name}
}

function generate_gpg_keys {
    local gpg_dir="$1"
    local gpg_key_type="$2"
    local gpg_key_length="$3"
    local gpg_key_usage="$4"
    local gpg_key_ring_name="$5"
    local gpg_key_ring_comment="$6"
    local gpg_key_ring_email="$7"
    local gpg_key_passphrase="$8"
    local gpg_key_expire_date="$9"
    local gpg_key_server="${10}"
    local gpg_key_ring_import_file="${11}"
    local gpg_passphrase_file="${12}"
    local gpg_secret_keys_file="${13}"

    echo "Removing GPG directory '${gpg_dir}'..." &>2
    rm -rf ${gpg_dir}*
    mkdir -p ${gpg_dir}

    echo "Creating GPG key ring import file '${gpg_key_ring_import_file}'..." &>2
    echo "Key-Type: ${gpg_key_type}" > ${gpg_key_ring_import_file}
    echo "Key-Length: ${gpg_key_length}" >> ${gpg_key_ring_import_file}
    echo "Key-Usage: ${gpg_key_usage}" >> ${gpg_key_ring_import_file}
    echo "Passphrase: ${gpg_key_passphrase}" >> ${gpg_key_ring_import_file}
    echo "Name-Real: ${gpg_key_ring_name}" >> ${gpg_key_ring_import_file}
    echo "Name-Comment: ${gpg_key_ring_comment}" >> ${gpg_key_ring_import_file}
    echo "Name-Email: ${gpg_key_ring_email}" >> ${gpg_key_ring_import_file}
    echo "Expire-Date: ${gpg_key_expire_date}" >> ${gpg_key_ring_import_file}
    echo "Keyserver: ${gpg_key_server}" >> ${gpg_key_ring_import_file}

    echo "Generating GPG key ring from import file '${gpg_key_ring_import_file}'..." &>2
    gpg2 --gen-key --batch ${gpg_key_ring_import_file}
    rm -f ${gpg_key_ring_import_file}

    echo "Searching for GPG public key ID for GPG key ring..." &>2
    local gpg_keys_info=`gpg2 --list-keys`
    read -ra gpg_keys_data <<< ${gpg_keys_info}
    for index in "${!gpg_keys_data[@]}"
    do
        local gpg_keys_data_value="${gpg_keys_data[index]}"
        if [ $(contains_string ${gpg_keys_data_value} ${gpg_key_ring_name}) == "true" ] ; then
            gpg_public_key_id_index=$((${index} - 7))
            gpg_public_key_id=`echo "${gpg_keys_data[gpg_public_key_id_index]}" | sed 's/ //g'`
            gpg_public_key_id=`echo "${gpg_public_key_id}" | sed 's/.*\///g'`
            break
        fi
    done

    if [ ${gpg_public_key_id} != "" ] ; then
        echo "Sending GPG public key ID to GPG key server '${gpg_key_server}'..." &>2
        gpg2 --keyserver ${gpg_key_server} --send-key ${gpg_public_key_id}
        echo ${gpg_key_passphrase} > ${gpg_passphrase_file}

        echo "Exporting GPG private/public keys..." &>2
        gpg2 --export-secret-keys -a ${gpg_public_key_id} > ${gpg_secret_keys_file}
        rm -f ${gpg_passphrase_file}
        echo ${gpg_public_key_id}
    fi
}

function generate_github_repo_ssh_keys {
    local ssh_dir="$1"
    local ssh_private_key_file="$2"
    local ssh_public_key_file="$3"
    local ssh_key_size="$4"
    local github_email="$5"

    echo "Generating SSH private/public keys for GitHub repo using GitHub email '${github_email}'..." &>2
    mkdir -p ${ssh_dir}
    cd ${ssh_dir}
    rm -f ${ssh_private_key_file}
    rm -f ${ssh_public_key_file}
    ssh-keygen -t rsa -b ${ssh_key_size} -C ${github_email} -f ${ssh_private_key_file} -N ""
    eval "$(ssh-agent -s)"
    ssh-add -k ${ssh_private_key_file}

    while IFS='' read -r line || [[ -n "$line" ]]; do
        private_key="${private_key}  $line\n"
    done < ${ssh_private_key_file}
}

function get_artifact_file {
    local artifact_id="$1"
    local artifact_file=`find $(pwd) -name ${artifact_id}*jar`
    echo ${artifact_file}
}

function get_artifact_id {
    local artifact_id=`awk '/rootProject.name/{print $NF; exit}' settings.gradle | sed s/\'//g`
    echo ${artifact_id}
}

function get_cd_up_path {
    local dir="$1"
    local character='/'

    if [[ $(string_ends_with ${dir} ${character}) == "true" ]] ; then
        dir+=/
    fi

    local count=`echo ${dir} | awk -F"${character}" '{print NF-1}'`

    if [[ "${count}" -eq 0 ]] ; then
        echo ""
    else
        local path=""
        for ((i = 1; i <= ${count}; i++));
        do
           path+="../"
        done
        echo ${path}
    fi
}

function get_current_date {
    local date=`TZ="America/New_York" date "+%Y-%m-%d"`
    echo ${date}
}

function get_current_timestamp {
    local timestamp=`TZ="America/New_York" date +"%F %T"`
    echo ${timestamp}
}

function get_github_repo_deploy_key_id {
    local github_api_uri="$1"
    local github_user="$2"
    local github_token="$3"
    local github_org="$4"
    local github_repo="$5"
    local github_deploy_key_title="$6"

    echo "Retrieving GitHub deploy key for repo '${github_repo}'..." &>2
    local json=`curl -u "${github_user}:${github_token}" "${github_api_uri}/repos/${github_org}/${github_repo}/keys"`
    local github_deploy_key_id=`echo ${json} | jq ".[] | select(.title == \"${github_deploy_key_title}\") | .id"`
    echo ${github_deploy_key_id}
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

function mask_string {
    local string="$1"
    while read -n1 character; do
        value+="x"
    done < <(echo -n "${string}")
    echo ${value}
}

function pcf_app_exists {
    local pcf_app_hostname="$1"
    local pcf_domain_name="$2"

    local pcf_app_domain="${pcf_app_hostname}.${pcf_domain_name}"
    local output=`cf apps`

    if [ $(contains_string ${output} ${pcf_app_domain}) == "true" ] ; then
        echo true
    else
        echo false
    fi
}

function pcf_create_config_server {
    local pcf_config_server_name="$1"
    local pcf_config_server_git_repo_uri="$2"
    local pcf_config_server_git_repo_branch="$3"
    local pcf_config_server_git_repo_private_key="$4"
    local pcf_service_type=p-config-server
    local pcf_service_plan=standard

    local private_key=$(format_rsa_key "${pcf_config_server_git_repo_private_key}")
    local json="{"
    json+="\"git\":{"
    json+="\"uri\":\"${pcf_config_server_git_repo_uri}\","
    json+="\"label\":\"${pcf_config_server_git_repo_branch}\","
    json+="\"privateKey\":\"${private_key}\""
    json+="}}"

    cf service ${pcf_config_server_name} || { \
        echo "Config Server ${pcf_config_server_name} not found. Creating new one..." >&2; \
        cf cs ${pcf_service_type} ${pcf_service_plan} ${pcf_config_server_name} -c ${json} ; \
        echo "Config Server ${pcf_config_server_name} created successfully! Waiting for service registry to initialize..." >&2
        until cf service ${pcf_config_server_name} | grep -m 1 "create succeeded"; do : ; done; \
        echo "Config Server ${pcf_config_server_name} initialization completed successfully!" >&2;
    }
}

function pcf_create_cups {
    local pcf_app_name="$1"
    local pcf_service_name="$2"
    local pcf_service_uri="$3"

    local json="{\"uri\":\"${pcf_service_uri}\"}"

    cf us ${pcf_app_name} ${pcf_service_name} || { \
        echo "CUPS ${pcf_service_name} not found. Cannot unbind. Continuing on..." >&2;
    }

    cf ds ${pcf_service_name} -f || { \
        echo "CUPS ${pcf_service_name} not found. Cannot delete. Continuing on..." >&2;
    }

    cf cups ${pcf_service_name} -p ${json}
    echo "CUPS ${pcf_service_name} create successfully!" >&2
}

function pcf_create_service {
    local pcf_app_name="$1"
    local pcf_service_name="$2"
    local pcf_service_type="$3"
    local pcf_service_plan="$4"

    cf us ${pcf_app_name} ${pcf_service_name} || { \
        echo "Service ${pcf_service_name} not found. Cannot unbind. Continuing on..." >&2;
    }

    cf ds ${pcf_service_name} -f || { \
        echo "Service ${pcf_service_name} not found. Cannot delete. Continuing on..." >&2;
    }

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
        echo "Service Registry ${pcf_service_registry_name} initialization completed successfully!" >&2;
    }
}

function pcf_deploy_blue {
    local pcf_app_name="$1"
    local pcf_domain_name="$2"

    local pcf_app_name_blue=$(pcf_get_blue_app_name ${pcf_app_name})
    local pcf_app_route_blue=${pcf_app_name}
    local pcf_app_name_green=$(pcf_get_green_app_name ${pcf_app_name})
    local pcf_app_route_green=${pcf_app_name}-deploy

    echo "Mapping route '${pcf_app_route_green}' of green app '${pcf_app_name_green}' to route '${pcf_app_route_blue}' of blue app '${pcf_app_name_blue}' in PCF..." &>2
    cf map-route ${pcf_app_name_green} ${pcf_domain_name} -n ${pcf_app_route_blue}

    echo "Un-mapping route '${pcf_app_route_blue}' of blue app '${pcf_app_name_blue}' in PCF..." &>2
    cf unmap-route ${pcf_app_name_blue} ${pcf_domain_name} -n ${pcf_app_route_blue}

    echo "Un-mapping route '${pcf_app_route_green}' of green app '${pcf_app_name_green}' in PCF..." &>2
    cf unmap-route ${pcf_app_name_green} ${pcf_domain_name} -n ${pcf_app_route_green}

    echo "Deleting route '${pcf_app_route_green}' of green app '${pcf_app_name_green}' in PCF..." &>2
    cf delete-route ${pcf_domain_name} -n ${pcf_app_route_green}

    echo "Deleting current blue app '${pcf_app_name_blue}' in PCF..." &>2
    cf delete ${pcf_app_name_blue} -f
}

function pcf_deploy_green {
    local pcf_app_name="$1"
    local pcf_domain_name="$2"

    local pcf_app_name_blue=$(pcf_get_blue_app_name ${pcf_app_name})
    local pcf_app_route_blue=${pcf_app_name}
    local pcf_app_name_green=$(pcf_get_green_app_name ${pcf_app_name})
    local pcf_app_route_green=${pcf_app_name}-deploy

    if [ $(pcf_app_exists ${pcf_app_route_blue} ${pcf_domain_name}) == "false" ] ; then
        echo "Deploying app '${pcf_app_name_green}' with route '${pcf_app_route_blue}' to PCF for first time..." &>2
        pcf_push ${pcf_app_name_green} ${pcf_app_route_blue}
    fi

    echo "Renaming current green app '${pcf_app_name_green}' to blue app '${pcf_app_name_blue}' in PCF..." &>2
    cf rename ${pcf_app_name_green} ${pcf_app_name_blue}

    echo "Deploying green app '${pcf_app_name_green}' with route '${pcf_app_route_green}' to PCF..." &>2
    pcf_push ${pcf_app_name_green} ${pcf_app_route_green}
}

function pcf_get_blue_app_name {
    local pcf_app_name="$1"
    local pcf_app_name_blue=${pcf_app_name}-blue
    echo ${pcf_app_name_blue}
}

function pcf_get_green_app_name {
    local pcf_app_name="$1"
    local pcf_app_name_green=${pcf_app_name}-green
    echo ${pcf_app_name_green}
}

function pcf_login {
    local pcf_api_endpoint_uri="$1"
    local pcf_org_name="$2"
    local pcf_space_name="$3"
    local pcf_username="$4"
    local pcf_password="$5"

    echo "Logging into PCF instance '${pcf_api_endpoint_uri}' for org '${pcf_org_name}' and space '${pcf_space_name}' via CF CLI..." &>2
    cf login \
        -a ${pcf_api_endpoint_uri} \
        -o ${pcf_org_name} \
        -s ${pcf_space_name} \
        -u ${pcf_username} \
        -p ${pcf_password} \
        --skip-ssl-validation
}

function pcf_push {
    local pcf_app_name="$1"
    local pcf_app_host_name="$2"
    local pcf_app_package="$3"
    local pcf_manifest="$4"

    echo "Pushing app '${pcf_app_name}' to PCF..." &>2
    if [ -d "${pcf_app_package}" ] && [ -d "${pcf_manifest}" ]; then
        cf push ${pcf_app_name} -n ${pcf_app_host_name} -p "${pcf_app_package}" -f "${pcf_manifest}"
    elif [ -d "${pcf_app_package}" ]; then
        cf push ${pcf_app_name} -n ${pcf_app_host_name} -p "${pcf_app_package}"
    elif [ -d "${pcf_manifest}" ]; then
        cf push ${pcf_app_name} -n ${pcf_app_host_name} -f "${pcf_manifest}"
    else
        cf push ${pcf_app_name} -n ${pcf_app_host_name}
    fi
}

function pcf_set_manifest_properties {
    local pcf_app_name="$1"
    local artifact_id="$2"

    echo "Setting PCF manifest properties..." >&2
    sed -e "s/name\:.*/name\: ${pcf_app_name}/g" manifest.yml -i
    sed -e "s/path\:.*/path\: ${artifact_id}\.jar/g" manifest.yml -i
}

function read_password_input {
    unset password;
    password=""
    while IFS= read -r -s -n1 input; do
      [[ -z ${input} ]] && { printf '\n' >&2; break; }
      if [[ ${input} == $'\x7f' ]]; then
          [[ -n ${password} ]] && password=${password%?}
          printf '\b \b' >&2
      else
        password+=${input}
        printf '*' >&2
      fi
    done
    echo ${password}
}

function remove_special_chars {
    local string="$1"
    local value=`echo ${string} | sed 's/[-_+. ]//g'`
    echo ${value}
}

function remove_special_chars_but_period {
    local string="$1"
    local value=`echo ${string} | sed 's/[-_+ ]//g'`
    echo ${value}
}

function remove_whitespace_chars {
    local string="$1"
    local value=`echo ${string} | sed 's/[ ]//g'`
    echo ${value}
}

function replace_special_chars_with_dash {
    local string="$1"
    local value=`echo ${string} | sed 's/[_+. ]/-/g'`
    echo ${value}
}

function replace_special_chars_with_whitespace {
    local string="$1"
    local value=`echo ${string} | sed 's/[-_+.]/ /g'`
    echo ${value}
}

function replace_string {
    local string="$1"
    local search_string="$2"
    local replace_string="$3"
    local value=`echo ${string} | sed "s/${search_string}/${replace_string}/g"`
    echo ${value}
}

function string_ends_with {
    local string="$1"
    local character="$2"

    if [[ "${string: -1}" == "${character}" ]] ; then
        echo false
    else
        echo true
    fi
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
