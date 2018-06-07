#!/usr/bin/env bash

function contains {
    string="$1"
    search_string="$2"

    if echo ${string} | grep -iqF "${search_string}"; then
        echo true
    else
        echo false
    fi
}

function create_github_deploy_key {
    github_api_uri="$1"
    github_user="$2"
    github_token="$3"
    github_org="$4"
    github_repo="$5"
    github_deploy_key_title="$6"
    github_deploy_key="$7"
    github_deploy_key_read_only=$8

    json="{ \"title\": \"${github_deploy_key_title}\", \"key\": \"${github_deploy_key}\", \"read_only\": ${github_deploy_key_read_only} }"
    curl -u "${github_user}:${github_token}" -d "${json}" -X POST "${github_api_uri}/repos/${github_org}/${github_repo}/keys"
}

function delete_github_deploy_key {
    github_api_uri="$1"
    github_user="$2"
    github_token="$3"
    github_org="$4"
    github_repo="$5"
    github_deploy_key_id="$6"

    curl -u "${github_user}:${github_token}" -X DELETE "${github_api_uri}/repos/${github_org}/${github_repo}/keys/${github_deploy_key_id}"
}

function generate_gpg_keys {
    gpg_dir="$1"
    gpg_key_type="$2"
    gpg_key_length="$3"
    gpg_key_usage="$4"
    gpg_key_passphrase="$5"
    gpg_key_ring_name="$6"
    gpg_key_ring_comment="$7"
    gpg_key_ring_email="$8"
    gpg_key_expire_date="$9"
    gpg_key_server="$10"
    gpg_key_ring_import_file="$11"
    gpg_private_key_file="$12"
    gpg_public_key_file="$13"

    sudo mkdir -p ${gpg_dir}
    rm -f ${gpg_key_private_key_file}
    rm -f ${gpg_key_public_key_file}

    echo "Key-Type: ${gpg_key_type}" > ${gpg_key_ring_import_file} >&2
    echo "Key-Length: ${gpg_key_length}" >> ${gpg_key_ring_import_file} >&2
    echo "Key-Usage: ${gpg_key_usage}" >> ${gpg_key_ring_import_file} >&2
    echo "Passphrase: ${gpg_key_passphrase}" >> ${gpg_key_ring_import_file} >&2
    echo "Name-Real: ${gpg_key_ring_name}" >> ${gpg_key_ring_import_file} >&2
    echo "Name-Comment: ${gpg_key_ring_comment}" >> ${gpg_key_ring_import_file} >&2
    echo "Name-Email: ${gpg_key_ring_email}" >> ${gpg_key_ring_import_file} >&2
    echo "Expire-Date: ${gpg_key_expire_date}" >> ${gpg_key_ring_import_file} >&2
    echo "Keyserver: ${gpg_key_server}" >> ${gpg_key_ring_import_file} >&2

    gpg2 --gen-key --batch "${gpg_key_ring_import_file}"
    gpg2 -a --export-secret-keys > "${gpg_key_private_key_file}"
    gpg2 --armor --export ${gpg_key_ring_email} > "${gpg_key_public_key_file}"
    rm -f "${gpg_key_ring_import_file}"

    gpg_keys_info=`gpg2 --list-keys`
    echo ${gpg_keys_info} | while read line ; do
        if [ $(contains ${line} "pub") == "true" ] ; then
            gpg_public_key_id=`echo ${line} | sed 's/pub//g'`
            gpg_public_key_id=`echo ${gpg_public_key_id} | sed 's/ .*//g'`
        fi
    done

    if [ "${gpg_public_key_id}" != "" ] ; then
        gpg2 --keyserver ${gpg_key_server} --send-key ${gpg_public_key_id}
    fi
}

function generate_github_ssh_keys {
    ssh_dir="$1"
    ssh_private_key_file="$2"
    ssh_public_key_file="$3"
    ssh_key_size=$4
    github_email="$5"

    sudo mkdir -p ${ssh_dir}
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
    github_api_uri="$1"
    github_user="$2"
    github_token="$3"
    github_org="$4"
    github_repo="$5"
    github_deploy_key_title="$6"

    json=`curl -u "${github_user}:${github_token}" "${github_api_uri}/repos/${github_org}/${github_repo}/keys"`
    github_deploy_key_id=`echo ${json} | jq ".[] | select(.title == \"${github_deploy_key_title}\") | .id"`
    echo ${github_deploy_key_id}
}

function get_group {
    group=`awk '/group/{print $NF}' build.gradle | sed s/\'//g`
    echo ${group}
}

function get_name {
    name=`awk '/rootProject.name/{print $NF}' settings.gradle | sed s/\'//g`
    echo ${name}
}

function get_pipeline_creds_storage {
    pipeline_creds_storage_option="$1"

    if [ "${pipeline_creds_storage_option}" == "CY" ] ; then
        echo "Credentials YAML"
    else
        echo "Vault"
    fi
}

function get_version {
    version=`sed 's/version=//g' gradle.properties`
    echo ${version}
}

function mask_string {
    string="$1"
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
    string="$1"
    value=`echo ${string} | sed 's/[-_+. ]//g'`
    echo ${value}
}

function remove_special_chars_but_period {
    string="$1"
    value=`echo ${string} | sed 's/[-_+ ]//g'`
    echo ${value}
}

function remove_whitespace_chars {
    string="$1"
    value=`echo ${string} | sed 's/[ ]//g'`
    echo ${value}
}

function replace_special_chars_with_dash {
    string="$1"
    value=`echo ${string} | sed 's/[_+. ]/-/g'`
    echo ${value}
}

function replace_special_chars_with_whitespace {
    string="$1"
    value=`echo ${string} | sed 's/[-_+.]/ /g'`
    echo ${value}
}

function replace_string {
    string="$1"
    search_string="$2"
    replace_string="$3"
    value=`echo ${string} | sed "s/${search_string}/${replace_string}/g"`
    echo ${value}
}

function to_lower_case {
    string="$1"
    value=`echo ${string} | awk '{print tolower($0)}'`
    echo ${value}
}

function to_title_case {
    string="$1"
    value=`echo ${string} | perl -ane 'foreach $wrd ( @F ) { print ucfirst($wrd)." "; } print "\n" ; '`
    echo ${value}
}

function to_upper_case {
    string="$1"
    value=`echo ${string} | awk '{print toupper($0)}'`
    echo ${value}
}
