#!/usr/bin/env bash

function contains {
    local string="$1"
    local search_string="$2"

    if echo ${string} | grep -iqF "${search_string}"; then
        echo true
    else
        echo false
    fi
}

function create_github_deploy_key {
    local github_api_uri="$1"
    local github_user="$2"
    local github_token="$3"
    local github_org="$4"
    local github_repo="$5"
    local github_deploy_key_title="$6"
    local github_deploy_key="$7"
    local github_deploy_key_read_only=$8

    local json="{ \"title\": \"${github_deploy_key_title}\", \"key\": \"${github_deploy_key}\", \"read_only\": ${github_deploy_key_read_only} }"
    curl -u "${github_user}:${github_token}" -d "${json}" -X POST "${github_api_uri}/repos/${github_org}/${github_repo}/keys"
}

function delete_github_deploy_key {
    local github_api_uri="$1"
    local github_user="$2"
    local github_token="$3"
    local github_org="$4"
    local github_repo="$5"
    local github_deploy_key_id="$6"

    curl -u "${github_user}:${github_token}" -X DELETE "${github_api_uri}/repos/${github_org}/${github_repo}/keys/${github_deploy_key_id}"
}

function generate_gpg_keys {
    local gpg_dir="$1"
    local gpg_key_type="$2"
    local gpg_key_length="$3"
    local gpg_key_usage="$4"
    local gpg_key_passphrase="$5"
    local gpg_key_ring_name="$6"
    local gpg_key_ring_comment="$7"
    local gpg_key_ring_email="$8"
    local gpg_key_expire_date="$9"
    local gpg_key_server="${10}"
    local gpg_key_ring_import_file="${11}"
    local gpg_passphrase_file="${12}"
    local gpg_secret_keys_file="${13}"

    rm -rf ${gpg_dir}*
    mkdir -p ${gpg_dir}

    echo "Key-Type: ${gpg_key_type}" > ${gpg_key_ring_import_file}
    echo "Key-Length: ${gpg_key_length}" >> ${gpg_key_ring_import_file}
    echo "Key-Usage: ${gpg_key_usage}" >> ${gpg_key_ring_import_file}
    echo "Passphrase: ${gpg_key_passphrase}" >> ${gpg_key_ring_import_file}
    echo "Name-Real: ${gpg_key_ring_name}" >> ${gpg_key_ring_import_file}
    echo "Name-Comment: ${gpg_key_ring_comment}" >> ${gpg_key_ring_import_file}
    echo "Name-Email: ${gpg_key_ring_email}" >> ${gpg_key_ring_import_file}
    echo "Expire-Date: ${gpg_key_expire_date}" >> ${gpg_key_ring_import_file}
    echo "Keyserver: ${gpg_key_server}" >> ${gpg_key_ring_import_file}

    gpg2 --gen-key --batch ${gpg_key_ring_import_file}
    rm -f "${gpg_key_ring_import_file}"

    local gpg_keys_info=`gpg2 --list-keys`
    read -ra gpg_keys_data <<< ${gpg_keys_info}
    for index in "${!gpg_keys_data[@]}"
    do
        local gpg_keys_data_value="${gpg_keys_data[index]}"
        if [ $(contains ${gpg_keys_data_value} ${gpg_key_ring_name}) == "true" ] ; then
            gpg_public_key_id_index=$((${index} - 7))
            gpg_public_key_id=`echo "${gpg_keys_data[gpg_public_key_id_index]}" | sed 's/ //g'`
            gpg_public_key_id=`echo "${gpg_public_key_id}" | sed 's/.*\///g'`
            break
        fi
    done

    if [ "${gpg_public_key_id}" != "" ] ; then
        gpg2 --keyserver ${gpg_key_server} --send-key ${gpg_public_key_id}
        echo ${gpg_key_passphrase} > ${gpg_passphrase_file}
        gpg2 --passphrase-fd ${gpg_passphrase_file} --export-secret-keys -a ${gpg_public_key_id} > ${gpg_secret_keys_file}
        rm -f ${gpg_passphrase_file}
        echo ${gpg_public_key_id}
    fi
}

function generate_github_ssh_keys {
    local ssh_dir="$1"
    local ssh_private_key_file="$2"
    local ssh_public_key_file="$3"
    local ssh_key_size=$4
    local github_email="$5"

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

function get_github_deploy_key_id {
    local github_api_uri="$1"
    local github_user="$2"
    local github_token="$3"
    local github_org="$4"
    local github_repo="$5"
    local github_deploy_key_title="$6"

    local json=`curl -u "${github_user}:${github_token}" "${github_api_uri}/repos/${github_org}/${github_repo}/keys"`
    local github_deploy_key_id=`echo ${json} | jq ".[] | select(.title == \"${github_deploy_key_title}\") | .id"`
    echo ${github_deploy_key_id}
}

function get_group {
    local group=`awk '/group/{print $NF}' build.gradle | sed s/\'//g`
    echo ${group}
}

function get_name {
    local name=`awk '/rootProject.name/{print $NF}' settings.gradle | sed s/\'//g`
    echo ${name}
}

function get_pipeline_creds_storage {
    local pipeline_creds_storage_option="$1"

    if [ "${pipeline_creds_storage_option}" == "CY" ] ; then
        echo "Credentials YAML"
    else
        echo "Vault"
    fi
}

function get_version {
    local version=`sed 's/version=//g' gradle.properties`
    echo ${version}
}

function mask_string {
    local string="$1"
    while read -n1 character; do
        value+="x"
    done < <(echo -n "${string}")
    echo ${value}
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
