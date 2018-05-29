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
    github_repo="$4"
    github_deploy_key_title="$5"
    github_deploy_key="$6"
    github_deploy_key_read_only=$7

    json="{ \"title\": \"${github_deploy_key_title}\", \"key\": \"${github_deploy_key}\", \"read_only\": ${github_deploy_key_read_only} }"
    curl -u "${github_user}:${github_token}" -d ${json} -X POST "${github_api_uri}/repos/${github_repo}/keys"
}

function delete_github_deploy_key {
    github_api_uri="$1"
    github_user="$2"
    github_token="$3"
    github_repo="$4"
    github_deploy_key_id="$5"

    curl -u "${github_user}:${github_token}" -X DELETE "${github_api_uri}/repos/${github_repo}/keys/${github_deploy_key_id}"
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
    github_repo="$4"
    github_deploy_key_title="$5"

    github_deploy_key_id=`curl -u "${github_user}:${github_token}" "${github_api_uri}/repos/${github_repo}/keys" | jq ".[] | select(.title == \"${github_deploy_key_title}\") | .id"`
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
