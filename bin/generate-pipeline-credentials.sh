#!/usr/bin/env bash

source_dir=$(dirname $0)
source ${source_dir}/shared/colors.sh
source ${source_dir}/shared/commons.sh
source ${source_dir}/config/properties.sh

echo -e "${cyan_color}*************************************************************************${no_color}"
echo -e "${cyan_color}OpenGood.io Cloud-Native App Concourse CI Pipeline Credentials Generator${no_color}"
echo -e "${cyan_color}*************************************************************************${no_color}"
echo ""

is_vault_installed=`vault --version`

if [ $(contains ${is_vault_installed} "command not found") == "true" ] ; then
    echo -e "${red_color}Vault CLI is not installed! Please install Vault CLI before continuing.${no_color}"
    echo ""
    exit 1
fi

echo -e "Enter value for project ${cyan_color}'name' (required)${no_color}, followed by [ENTER]:"
read name
echo ""

if [ "${name}" == "" ] ; then
    echo -e "${red_color}ERROR! Project 'name' not entered! Please try again.${no_color}"
    echo ""
    exit 1
fi

name=$(to_lower_case ${name})
name=$(replace_special_chars_with_dash ${name})
pipeline_name=${name}

echo -e "Enter value for Concourse CI ${cyan_color}'concourseTeamName' (default: ${default_concourse_team_name})${no_color}, followed by [ENTER]:"
read concourse_team_name
echo ""

if [ "${concourse_team_name}" == "" ] ; then
    concourse_team_name=${default_concourse_team_name}
fi

concourse_team_name=$(to_lower_case "${concourse_team_name}")
concourse_team_name=$(replace_special_chars_with_dash "${concourse_team_name}")

echo -e "Does your ${yellow_color}cloud-native project${no_color} share previously set up ${yellow_color}GitHub credentials${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_github_creds
echo ""

has_github_creds=`echo $(to_upper_case "${has_github_creds}")`

if [ "${has_github_creds}" == "N" ] ; then
    echo -e "Enter value for ${cyan_color}'githubUser' (required)${no_color}, followed by [ENTER]:"
    read github_user
    echo ""

    if [ "${github_user}" == "" ] ; then
        echo -e "${red_color}ERROR! 'githubUser' not entered! Please try again.${no_color}"
        echo ""
        exit 1
    fi

    echo -e "Enter value for ${cyan_color}'githubToken' (required)${no_color}, followed by [ENTER]:"
    github_token=$(read_password_input)
    echo ""

    if [ "${github_token}" == "" ] ; then
        echo -e "${red_color}ERROR! 'githubToken' not entered! Please try again.${no_color}"
        echo ""
        exit 1
    fi
else
    github_user=""
    github_token=""
fi

echo -e "Does your ${yellow_color}cloud-native project${no_color} use a ${yellow_color}shared pipeline${no_color} with a previously set up ${yellow_color}GitHub repo deploy key${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_shared_pipeline_github_deploy_key
echo ""

has_shared_pipeline_github_deploy_key=`echo $(to_upper_case "${has_shared_pipeline_github_deploy_key}")`

if [ "${has_shared_pipeline_github_deploy_key}" == "N" ] ; then
    echo -e "Enter value for ${cyan_color}'githubSharedPipelineEmail' (required)${no_color}, followed by [ENTER]:"
    read github_shared_pipeline_email
    echo ""

    if ! [[ ${github_shared_pipeline_email} =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
        echo -e "${red_color}ERROR! GitHub email address in NOT form [[A-Za-Z][0-9]@[A-Za-Z][0-9].[A-Za-Z][0-9]] (i.e. user@domain.com)! Please try again.${no_color}"
        exit 1
    fi
else
    github_shared_pipeline_email=""
fi

echo -e "Does your ${yellow_color}cloud-native project${no_color} use a ${yellow_color}shared pipeline${no_color} with a previously set up ${yellow_color}GitHub repo and branch${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_github_shared_pipeline_repo_branch
echo ""

has_github_shared_pipeline_repo_branch=`echo $(to_upper_case "${has_github_shared_pipeline_repo_branch}")`

if [ "${has_github_shared_pipeline_repo_branch}" == "N" ] ; then
    echo -e "Enter value for ${cyan_color}'githubSharedPipelineRepo' (required)${no_color}, followed by [ENTER]:"
    read github_shared_pipeline_repo_uri
    echo ""

    if [ "${github_shared_pipeline_repo_uri}" == "" ] ; then
        echo -e "${red_color}ERROR! 'githubSharedPipelineRepo' not entered! Please try again.${no_color}"
        echo ""
        exit 1
    fi

    github_shared_pipeline_repo_uri=$(replace_string ${github_repo_uri} "repo" ${github_shared_pipeline_repo_uri})

    echo -e "Enter value for ${cyan_color}'githubSharedPipelineRepoBranch' (default: ${github_repo_default_branch})${no_color}, followed by [ENTER]:"
    read github_shared_pipeline_repo_branch
    echo ""

    if [ "${github_shared_pipeline_repo_branch}" == "" ] ; then
        github_shared_pipeline_repo_branch=${github_repo_default_branch}
    fi
else
    github_shared_pipeline_repo_uri=""
    github_shared_pipeline_repo_branch=""
fi

echo -e "Does your ${yellow_color}cloud-native project's pipeline${no_color} share a previously set up ${yellow_color}GitHub repo deploy key${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_github_project_deploy_key
echo ""

has_github_project_deploy_key=`echo $(to_upper_case "${has_github_project_deploy_key}")`

if [ "${has_github_project_deploy_key}" == "N" ] ; then
    echo -e "Enter value for ${cyan_color}'githubProjectEmail' (required)${no_color}, followed by [ENTER]:"
    read github_project_email
    echo ""

    if ! [[ ${github_project_email} =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
        echo -e "${red_color}ERROR! GitHub email address in NOT form [[A-Za-Z][0-9]@[A-Za-Z][0-9].[A-Za-Z][0-9]] (i.e. user@domain.com)! Please try again.${no_color}"
        exit 1
    fi
else
    github_project_email=""
fi

echo -e "Does your ${yellow_color}cloud-native project's pipeline${no_color} share a previously set up ${yellow_color}GitHub repo and branch${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_github_project_repo_branch
echo ""

has_github_project_repo_branch=`echo $(to_upper_case "${has_github_project_repo_branch}")`

if [ "${has_github_project_repo_branch}" == "N" ] ; then
    echo -e "Enter value for ${cyan_color}'githubProjectRepo' (default: ${name})${no_color}, followed by [ENTER]:"
    read github_project_repo_uri
    echo ""

    if [ "${github_project_repo_uri}" == "" ] ; then
        github_project_repo_uri=${name}
    fi

    github_project_repo_uri=$(replace_string ${github_repo_uri} "repo" ${github_project_repo_uri})

    echo -e "Enter value for ${cyan_color}'githubProjectRepoBranch' (default: ${github_repo_default_branch})${no_color}, followed by [ENTER]:"
    read github_project_repo_branch
    echo ""

    if [ "${github_project_repo_branch}" == "" ] ; then
        github_project_repo_branch=${github_repo_default_branch}
    fi
else
    github_project_repo_uri=""
    github_project_repo_branch=""
fi

echo -e "Does your ${yellow_color}cloud-native project${no_color} need to publish its own ${yellow_color}Docker image(s)${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_docker
echo ""

has_docker=`echo $(to_upper_case "${has_docker}")`

if [ "${has_docker}" == "Y" ] ; then
    echo -e "Does your ${yellow_color}cloud-native project${no_color} share previously set up ${yellow_color}Docker credentials${no_color}?"
    echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
    read has_docker_creds
    echo ""

    has_docker_creds=`echo $(to_upper_case "${has_docker_creds}")`

    if [ "${has_docker_creds}" == "N" ] ; then
        echo -e "Enter value for ${cyan_color}'dockerUserName' (required)${no_color}, followed by [ENTER]:"
        read docker_username
        echo ""

        if [ "${docker_username}" == "" ] ; then
            echo -e "${red_color}ERROR! 'dockerUserName' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi

        echo -e "Enter value for ${cyan_color}'dockerPassword' (required)${no_color}, followed by [ENTER]:"
        docker_password=$(read_password_input)
        echo ""

        if [ "${docker_password}" == "" ] ; then
            echo -e "${red_color}ERROR! 'dockerPassword' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi
    else
        docker_username=""
        docker_password=""
    fi
else
    docker_username=""
    docker_password=""
fi

echo -e "Does your ${yellow_color}cloud-native project${no_color} reside on ${yellow_color}PCF${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_pcf
echo ""

has_pcf=`echo $(to_upper_case "${has_pcf}")`

if [ "${has_pcf}" == "Y" ] ; then
    echo -e "Does your ${yellow_color}cloud-native project${no_color} share a previously set up ${yellow_color}PCF API endpoint, organization, and space${no_color}?"
    echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
    read has_pcf_api_org_space
    echo ""

    has_pcf_api_org_space=`echo $(to_upper_case "${has_pcf_api_org_space}")`

    if [ "${has_pcf_api_org_space}" == "N" ] ; then
        echo -e "Enter value for ${cyan_color}'pcfApiEndpoint' (default: ${default_pcf_api_endpoint})${no_color}, followed by [ENTER]:"
        read pcf_api_endpoint
        echo ""

        if [ "${pcf_api_endpoint}" == "" ] ; then
            pcf_api_endpoint=${default_pcf_api_endpoint}
        fi

        echo -e "Enter value for ${cyan_color}'pcfOrg' (default: ${default_pcf_org_name})${no_color}, followed by [ENTER]:"
        read pcf_org_name
        echo ""

        if [ "${pcf_org_name}" == "" ] ; then
            pcf_org_name=${default_pcf_org_name}
        fi

        pcf_org_name=$(to_lower_case ${pcf_org_name})
        pcf_org_name=$(replace_special_chars_with_dash ${pcf_org_name})

        echo -e "Enter value for ${cyan_color}'pcfSpace' (default: ${default_pcf_space_name})${no_color}, followed by [ENTER]:"
        read pcf_space_name
        echo ""

        if [ "${pcf_space_name}" == "" ] ; then
            pcf_space_name=${default_pcf_space_name}
        fi

        pcf_space_name=$(to_lower_case ${pcf_space_name})
        pcf_space_name=$(replace_special_chars_with_dash ${pcf_space_name})
    else
        pcf_api_endpoint=""
        pcf_org_name=""
        pcf_space_name=""
    fi

    echo -e "Does your ${yellow_color}cloud-native project${no_color} share previously set up ${yellow_color}PCF credentials${no_color}?"
    echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
    read has_pcf_creds
    echo ""

    has_pcf_creds=`echo $(to_upper_case "${has_pcf_creds}")`

    if [ "${has_pcf_creds}" == "N" ] ; then
        echo -e "Enter value for ${cyan_color}'pcfUserName' (required)${no_color}, followed by [ENTER]:"
        read pcf_username
        echo ""

        if [ "${pcf_username}" == "" ] ; then
            echo -e "${red_color}ERROR! 'pcfUserName' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi

        echo -e "Enter value for ${cyan_color}'pcfPassword' (required)${no_color}, followed by [ENTER]:"
        pcf_password=$(read_password_input)
        echo ""

        if [ "${pcf_password}" == "" ] ; then
            echo -e "${red_color}ERROR! 'pcfPassword' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi
    else
        pcf_username=""
        pcf_password=""
    fi
else
    pcf_api_endpoint=""
    pcf_org_name=""
    pcf_space_name=""
    pcf_username=""
    pcf_password=""
fi

echo -e "Does your ${yellow_color}cloud-native project${no_color} have a ${yellow_color}database${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_db
echo ""

has_db=`echo $(to_upper_case "${has_db}")`

if [ "${has_db}" == "Y" ] ; then
    echo -e "Does your ${yellow_color}cloud-native project${no_color} share previously set up ${yellow_color}database credentials${no_color}?"
    echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
    read has_db_creds
    echo ""

    has_db_creds=`echo $(to_upper_case "${has_db_creds}")`

    if [ "${has_db_creds}" == "N" ] ; then
        echo -e "Enter value for ${cyan_color}'dbUserName' (required)${no_color}, followed by [ENTER]:"
        read db_username
        echo ""

        if [ "${db_username}" == "" ] ; then
            echo -e "${red_color}ERROR! 'dbUserName' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi

        echo -e "Enter value for ${cyan_color}'dbPassword' (required)${no_color}, followed by [ENTER]:"
        db_password=$(read_password_input)
        echo ""

        if [ "${db_password}" == "" ] ; then
            echo -e "${red_color}ERROR! 'dbPassword' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi
    else
        db_username=""
        db_password=""
    fi
else
    db_username=""
    db_password=""
fi

echo -e "Does your ${yellow_color}cloud-native project${no_color} need to be published to ${yellow_color}Maven Central public artifact repo${no_color}?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_publish_maven_central_repo
echo ""

has_publish_maven_central_repo=`echo $(to_upper_case "${has_publish_maven_central_repo}")`

if [ "${has_publish_maven_central_repo}" == "Y" ] ; then
    echo -e "Does your ${yellow_color}cloud-native project${no_color} share previously set up ${yellow_color}Maven Central credentials${no_color}?"
    echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
    read has_maven_central_creds
    echo ""

    has_maven_central_creds=`echo $(to_upper_case "${has_maven_central_creds}")`

    if [ "${has_maven_central_creds}" == "N" ] ; then
        echo -e "Enter value for ${cyan_color}'mavenCentralUserName' (required)${no_color}, followed by [ENTER]:"
        read maven_central_username
        echo ""

        if [ "${maven_central_username}" == "" ] ; then
            echo -e "${red_color}ERROR! 'mavenCentralUserName' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi

        echo -e "Enter value for ${cyan_color}'mavenCentralPassword' (required)${no_color}, followed by [ENTER]:"
        maven_central_password=$(read_password_input)
        echo ""

        if [ "${maven_central_password}" == "" ] ; then
            echo -e "${red_color}ERROR! 'mavenCentralPassword' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi
    else
        maven_central_username=""
        maven_central_password=""
    fi

    echo -e "Does your ${yellow_color}cloud-native project${no_color} share previously set up ${yellow_color}Maven Central GPG key ring${no_color}?"
    echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
    read has_maven_central_gpg_key_ring
    echo ""

    has_maven_central_gpg_key_ring=`echo $(to_upper_case "${has_maven_central_gpg_key_ring}")`

    if [ "${has_maven_central_gpg_key_ring}" == "N" ] ; then
        echo -e "Enter value for ${cyan_color}'mavenCentralGpgKeyRingName' (required)${no_color}, followed by [ENTER]:"
        read maven_central_gpg_key_ring_name
        echo ""

        if [ "${maven_central_gpg_key_ring_name}" == "" ] ; then
            echo -e "${red_color}ERROR! 'mavenCentralGpgKeyRingName' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi

        echo -e "Enter value for ${cyan_color}'mavenCentralGpgKeyRingComment' (required)${no_color}, followed by [ENTER]:"
        read maven_central_gpg_key_ring_comment
        echo ""

        if [ "${maven_central_gpg_key_ring_comment}" == "" ] ; then
            echo -e "${red_color}ERROR! 'mavenCentralGpgKeyRingComment' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi

        echo -e "Enter value for ${cyan_color}'mavenCentralGpgKeyRingEmail' (required)${no_color}, followed by [ENTER]:"
        read maven_central_gpg_key_ring_email
        echo ""

        if [ "${maven_central_gpg_key_ring_email}" == "" ] ; then
            echo -e "${red_color}ERROR! 'mavenCentralGpgKeyRingEmail' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi

        echo -e "Enter value for ${cyan_color}'mavenCentralGpgKeyRingPassphrase' (required)${no_color}, followed by [ENTER]:"
        maven_central_gpg_key_passphrase=$(read_password_input)
        echo ""

        if [ "${maven_central_gpg_key_passphrase}" == "" ] ; then
            echo -e "${red_color}ERROR! 'mavenCentralGpgKeyRingPassphrase' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi
    else
        maven_central_gpg_key_ring_name=""
        maven_central_gpg_key_ring_comment=""
        maven_central_gpg_key_ring_email=""
        maven_central_gpg_key_passphrase=""
    fi
else
    maven_central_username=""
    maven_central_password=""
    maven_central_gpg_key_ring_name=""
    maven_central_gpg_key_ring_comment=""
    maven_central_gpg_key_ring_email=""
    maven_central_gpg_key_passphrase=""
fi

echo -e "How do you want to ${yellow_color}store your project's pipeline credentials${no_color}?"
echo -e "Enter ${cyan_color}'CY'${no_color} for 'Credentials YAML' and ${cyan_color}'V'${no_color} for Vault or leave blank, followed by [ENTER]:"
read pipeline_creds_storage_option
echo ""

pipeline_creds_storage_option=$(to_lower_case ${pipeline_creds_storage_option})
pipeline_creds_storage_option=$(remove_special_chars ${pipeline_creds_storage_option})

if [ "${pipeline_creds_storage_option}" != "CY" ] && [ "${pipeline_creds_storage_option}" != "V" ] ; then
    pipeline_creds_storage_option="V"
fi

echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Pipeline credentials information${no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo ""
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Pipeline${no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}      Pipeline name: ${pipeline_name}${no_color}"
echo -e "${cyan_color}Credentials storage: $(get_pipeline_creds_storage ${pipeline_creds_storage_option})${no_color}"
echo ""
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Concourse CI${no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Team name: ${concourse_team_name}${no_color}"
echo ""

if [ "${github_user}" != "" ] &&
    [ "${github_token}" != "" ] ||
    [ "${github_shared_pipeline_email}" != "" ] ||
    [ "${github_shared_pipeline_repo_uri}" != "" ] &&
    [ "${github_shared_pipeline_repo_branch}" != "" ] ||
    [ "${github_project_email}" != "" ] ||
    [ "${github_project_repo_uri}" != "" ] &&
    [ "${github_project_repo_branch}" != "" ] ; then
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}GitHub${no_color}"
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}                  User: ${github_user}${no_color}"
    echo -e "${cyan_color}                 Token: $(mask_string ${github_token})${no_color}"
    echo -e "${cyan_color} Shared pipeline email: ${github_shared_pipeline_email}${no_color}"
    echo -e "${cyan_color}  Shared pipeline repo: ${github_shared_pipeline_repo_uri}${no_color}"
    echo -e "${cyan_color}Shared pipeline branch: ${github_shared_pipeline_repo_branch}${no_color}"
    echo -e "${cyan_color}         Project email: ${github_project_email}${no_color}"
    echo -e "${cyan_color}          Project repo: ${github_project_repo_uri}${no_color}"
    echo -e "${cyan_color}        Project branch: ${github_project_repo_branch}${no_color}"
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo ""
fi

if [ "${docker_username}" != "" ] && [ "${docker_password}" != "" ] ; then
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}Docker${no_color}"
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}Username: ${docker_username}${no_color}"
    echo -e "${cyan_color}Password: $(mask_string ${docker_password})${no_color}"
    echo ""
fi

if [ "${pcf_api_endpoint}" != "" ] && \
    [ "${pcf_org_name}" != "" ] && \
    [ "${pcf_space_name}" != "" ] || \
    [ "${pcf_username}" != "" ] && \
    [ "${pcf_password}" != "" ]; then
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}PCF${no_color}"
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}     API endpoint: ${pcf_api_endpoint}${no_color}"
    echo -e "${cyan_color}Organization name: ${pcf_org_name}${no_color}"
    echo -e "${cyan_color}       Space name: ${pcf_space_name}${no_color}"
    echo -e "${cyan_color}         Username: ${pcf_username}${no_color}"
    echo -e "${cyan_color}         Password: $(mask_string ${pcf_password})${no_color}"
    echo ""
fi

if [ "${db_username}" != "" ] && [ "${db_password}" != "" ] ; then
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}Database${no_color}"
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}Username: ${db_username}${no_color}"
    echo -e "${cyan_color}Password: $(mask_string ${db_password})${no_color}"
    echo ""
fi

if [ "${maven_central_username}" != "" ] && \
    [ "${maven_central_password}" != "" ] || \
    [ "${maven_central_gpg_key_ring_name}" != "" ] && \
    [ "${maven_central_gpg_key_ring_comment}" != "" ] && \
    [ "${maven_central_gpg_key_ring_email}" != "" ] && \
    [ "${maven_central_gpg_key_passphrase}" != "" ]; then
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}Maven Central${no_color}"
    echo -e "${cyan_color}===================================================================================${no_color}"
    echo -e "${cyan_color}               Username: ${maven_central_username}${no_color}"
    echo -e "${cyan_color}               Password: $(mask_string ${maven_central_password})${no_color}"
    echo -e "${cyan_color}      GPG key ring name: ${maven_central_gpg_key_ring_name}${no_color}"
    echo -e "${cyan_color}   GPG key ring comment: ${maven_central_gpg_key_ring_comment}${no_color}"
    echo -e "${cyan_color}     GAG key ring email: ${maven_central_gpg_key_ring_email}${no_color}"
    echo -e "${cyan_color}GPG key ring passphrase: $(mask_string ${maven_central_gpg_key_passphrase})${no_color}"
    echo ""
fi

if [ "${github_shared_pipeline_email}" != "" ] ; then
    ssh_private_key_file=${ssh_dir}/${shared_pipeline_project}_rsa
    ssh_public_key_file=${ssh_dir}/${shared_pipeline_project}_rsa.pub

    echo -e "${cyan_color}Generating SSH private/public keys for shared pipeline GitHub repo deploy key using GitHub email address '${github_shared_pipeline_email}'...${no_color}"
    shared_pipeline_git_repo_private_key=$(generate_github_ssh_keys \
        "${ssh_dir}" \
        "${ssh_private_key_file}" \
        "${ssh_public_key_file}" \
        ${ssh_key_size} \
        "${github_shared_pipeline_email}")
    shared_pipeline_git_repo_private_key=`cat ${ssh_private_key_file}`
    shared_pipeline_git_repo_public_key=`cat ${ssh_public_key_file}`
    echo -e "${green_color}Done!${no_color}"
    echo ""
fi

if [ "${github_project_email}" != "" ] ; then
    ssh_private_key_file=${ssh_dir}/${name}_rsa
    ssh_public_key_file=${ssh_dir}/${name}_rsa.pub

    echo -e "${cyan_color}Generating SSH private/public keys for project GitHub repo deploy key using GitHub email address '${github_project_email}'...${no_color}"
    generate_github_ssh_keys "${ssh_dir}" "${ssh_private_key_file}" "${ssh_public_key_file}" ${ssh_key_size} "${github_project_email}"
    project_git_repo_private_key=`cat ${ssh_private_key_file}`
    project_git_repo_public_key=`cat ${ssh_public_key_file}`
    echo -e "${green_color}Done!${no_color}"
    echo ""
fi

if [ "${maven_central_gpg_key_ring_name}" != "" ] &&
    [ "${maven_central_gpg_key_ring_comment}" != "" ] &&
    [ "${maven_central_gpg_key_ring_email}" != "" ] &&
    [ "${maven_central_gpg_key_passphrase}" != "" ] ; then
    echo -e "${cyan_color}Generating GPG private/public keys for Maven Central project artifacts repos...${no_color}"
    maven_central_gpg_key_id=$(generate_gpg_keys \
        "${gpg_dir}" \
        "${gpg_key_type}" \
        "${gpg_key_length}" \
        "${gpg_key_usage}" \
        "${maven_central_gpg_key_ring_name}" \
        "${maven_central_gpg_key_ring_comment}" \
        "${maven_central_gpg_key_ring_email}" \
        "${maven_central_gpg_key_passphrase}" \
        "${gpg_key_expire_date}" \
        "${gpg_key_server}" \
        "${gpg_key_ring_import_file}" \
        "${gpg_passphrase_file}" \
        "${gpg_secret_keys_file}")
    maven_central_gpg_secret_keys=`cat ${gpg_secret_keys_file}`
    echo -e "${green_color}Done!${no_color}"
    echo ""
fi

if [ "${pipeline_creds_storage_option}" == "V" ] ; then
    if [ "${github_user}" != "" ] && [ "${github_token}" != "" ] ; then
        echo -e "${cyan_color}Storing GitHub credentials into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/github-user value=${github_user}
        vault write concourse/${concourse_team_name}/github-token value=${github_token}
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${github_shared_pipeline_email}" != "" ] ; then
        echo -e "${cyan_color}Storing GitHub private key for shared pipeline GitHub deploy key into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/shared-pipeline-git-repo-private-key value="${shared_pipeline_git_repo_private_key}"
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${github_shared_pipeline_repo_uri}" != "" ] && [ "${github_shared_pipeline_repo_branch}" != "" ] ; then
        echo -e "${cyan_color}Storing GitHub repo URI and branch for shared pipeline into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/shared-pipeline-git-repo-uri value="${github_shared_pipeline_repo_uri}"
        vault write concourse/${concourse_team_name}/shared-pipeline-git-repo-branch value="${github_shared_pipeline_repo_branch}"
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${github_project_email}" != "" ] ; then
        echo -e "${cyan_color}Storing GitHub private key for project GitHub deploy key into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/${pipeline_name}/project-git-repo-private-key value="${project_git_repo_private_key}"
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${github_project_repo_uri}" != "" ] && [ "${github_project_repo_branch}" != "" ] ; then
        echo -e "${cyan_color}Storing GitHub repo URI and branch for project pipeline into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/${pipeline_name}/project-git-repo-uri value="${github_project_repo_uri}"
        vault write concourse/${concourse_team_name}/${pipeline_name}/project-git-repo-branch value="${github_project_repo_branch}"
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${docker_username}" != "" ] && [ "${docker_password}" != "" ] ; then
        echo -e "${cyan_color}Storing Docker shared credentials into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/docker-username value=${docker_username}
        vault write concourse/${concourse_team_name}/docker-password value=${docker_password}
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${pcf_api_endpoint}" != "" ] && [ "${pcf_org_name}" != "" ] && [ "${pcf_space_name}" != "" ] ; then
        echo -e "${cyan_color}Storing PCF shared API endpoint, organization, and space into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/pcf-api-endpoint value=${pcf_api_endpoint}
        vault write concourse/${concourse_team_name}/pcf-org-name value=${pcf_org_name}
        vault write concourse/${concourse_team_name}/pcf-space-name value=${pcf_space_name}
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${pcf_username}" != "" ] && [ "${pcf_password}" != "" ] ; then
        echo -e "${cyan_color}Storing PCF shared credentials into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/pcf-username value=${pcf_username}
        vault write concourse/${concourse_team_name}/pcf-password value=${pcf_password}
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${db_username}" != "" ] && [ "${db_password}" != "" ] ; then
        echo -e "${cyan_color}Storing DB credentials into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/${pipeline_name}/db-username value=${db_username}
        vault write concourse/${concourse_team_name}/${pipeline_name}/db-password value=${db_password}
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${maven_central_username}" != "" ] && [ "${maven_central_password}" != "" ] ; then
        echo -e "${cyan_color}Storing Maven Central credentials into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/maven-central-username value=${maven_central_username}
        vault write concourse/${concourse_team_name}/maven-central-password value=${maven_central_password}
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi

    if [ "${maven_central_gpg_key_ring_name}" != "" ] &&
        [ "${maven_central_gpg_key_ring_comment}" != "" ] &&
        [ "${maven_central_gpg_key_ring_email}" != "" ] &&
        [ "${maven_central_gpg_key_passphrase}" != "" ] &&
        [ "${maven_central_gpg_key_id}" != "" ] &&
        [ "${maven_central_gpg_secret_keys}" != "" ] ; then
        echo -e "${cyan_color}Storing Maven Central GPG key passphrase and private/public keys into Vault for Concourse CI pipeline...${no_color}"
        vault write concourse/${concourse_team_name}/maven-central-gpg-key-ring-name value=${maven_central_gpg_key_ring_name}
        vault write concourse/${concourse_team_name}/maven-central-gpg-key-ring-comment value="${maven_central_gpg_key_ring_comment}"
        vault write concourse/${concourse_team_name}/maven-central-gpg-key-ring-email value=${maven_central_gpg_key_ring_email}
        vault write concourse/${concourse_team_name}/maven-central-gpg-key-passphrase value=${maven_central_gpg_key_passphrase}
        vault write concourse/${concourse_team_name}/maven-central-gpg-key-id value=${maven_central_gpg_key_id}
        vault write concourse/${concourse_team_name}/maven-central-gpg-secret-keys value=@${gpg_secret_keys_file}
        echo -e "${green_color}Done!${no_color}"
        echo ""
    fi
fi

if [ "${pipeline_creds_storage_option}" == "CY" ] ; then
    echo -e "${cyan_color}Generating pipeline credentials file '${pipeline_credentials_file}'...${no_color}"

    cd ${project_dir}/ci
    rm -rf ${pipeline_credentials_file}

    echo "---" > ${pipeline_credentials_file}
    echo "docker-username: ${docker_username}" >> ${pipeline_credentials_file}
    echo "docker-password: ${docker_password}" >> ${pipeline_credentials_file}
    echo "pcf-api-endpoint: ${pcf_api_endpoint}" >> ${pipeline_credentials_file}
    echo "pcf-org-name: ${pcf_org_name}" >> ${pipeline_credentials_file}
    echo "pcf-space-name: ${pcf_space_name}" >> ${pipeline_credentials_file}
    echo "pcf-username: ${pcf_username}" >> ${pipeline_credentials_file}
    echo "pcf-password: ${pcf_password}" >> ${pipeline_credentials_file}
    echo "db-username: ${db_username}" >> ${pipeline_credentials_file}
    echo "db-password: ${db_password}" >> ${pipeline_credentials_file}
    echo "shared-pipeline-git-repo-uri: ${github_shared_pipeline_repo_uri}" >> ${pipeline_credentials_file}
    echo "shared-pipeline-git-repo-branch: ${github_shared_pipeline_repo_branch}" >> ${pipeline_credentials_file}
    echo "shared-pipeline-git-repo-private-key: |" >> ${pipeline_credentials_file}
    echo -e "${shared_pipeline_git_repo_private_key}" >> ${pipeline_credentials_file}
    echo "project-git-repo-uri: ${github_project_repo_uri}" >> ${pipeline_credentials_file}
    echo "project-git-repo-branch: ${github_project_repo_branch}" >> ${pipeline_credentials_file}
    echo "project-git-repo-private-key: |" >> ${pipeline_credentials_file}
    echo -e "${project_git_repo_private_key}" >> ${pipeline_credentials_file}
    echo "maven_central-username: ${maven_central_username}" >> ${pipeline_credentials_file}
    echo "maven_central-password: ${maven_central_password}" >> ${pipeline_credentials_file}
    echo "maven-central-gpg-key-ring-name: ${maven_central_gpg_key_ring_name}" >> ${pipeline_credentials_file}
    echo "maven-central-gpg-key-ring-comment: ${maven_central_gpg_key_ring_comment}" >> ${pipeline_credentials_file}
    echo "maven-central-gpg-key-ring-email: ${maven_central_gpg_key_ring_email}" >> ${pipeline_credentials_file}
    echo "maven-central-gpg-key-passphrase: ${maven_central_gpg_key_passphrase}" >> ${pipeline_credentials_file}
    echo "maven-central-gpg-key-id: ${maven_central_gpg_key_id}" >> ${pipeline_credentials_file}

    echo -e "${green_color}Done!${no_color}"
    echo ""
fi

if [ "${github_shared_pipeline_email}" != "" ] ; then
    echo -e "${cyan_color}Creating shared pipeline GitHub repo deploy key...${no_color}"

    github_user=`vault read /concourse/${concourse_team_name}/github-user | grep "value" | awk '{print $2}'`
    github_token=`vault read /concourse/${concourse_team_name}/github-token | grep "value" | awk '{print $2}'`

    github_deploy_key_id=$(get_github_deploy_key_id \
        "${github_api_uri}" \
        "${github_user}" \
        "${github_token}" \
        "${github_org}" \
        "${shared_pipeline_project}" \
        "${github_deploy_key_title}")

    if [ "${github_deploy_key_id}" != "" ] ; then
        delete_github_deploy_key \
            "${github_api_uri}" \
            "${github_user}" \
            "${github_token}" \
            "${github_org}" \
            "${shared_pipeline_project}" \
            "${github_deploy_key_id}"
    fi

    create_github_deploy_key \
        "${github_api_uri}" \
        "${github_user}" \
        "${github_token}" \
        "${github_org}" \
        "${shared_pipeline_project}" \
        "${github_deploy_key_title}" \
        "${shared_pipeline_git_repo_public_key}" \
        "true"

    echo -e "${green_color}Done!${no_color}"
    echo ""
fi

if [ "${github_project_email}" != "" ] ; then
    echo -e "${cyan_color}Creating project GitHub repo deploy key...${no_color}"

    github_user=`vault read /concourse/${concourse_team_name}/github-user | grep "value" | awk '{print $2}'`
    github_token=`vault read /concourse/${concourse_team_name}/github-token | grep "value" | awk '{print $2}'`

    github_deploy_key_id=$(get_github_deploy_key_id \
        "${github_api_uri}" \
        "${github_user}" \
        "${github_token}" \
        "${github_org}" \
        "${name}" \
        "${github_deploy_key_title}")

    if [ "${github_deploy_key_id}" != "" ] ; then
        delete_github_deploy_key \
            "${github_api_uri}" \
            "${github_user}" \
            "${github_token}" \
            "${github_org}" \
            "${name}" \
            "${github_deploy_key_id}"
    fi

    create_github_deploy_key \
        "${github_api_uri}" \
        "${github_user}" \
        "${github_token}" \
        "${github_org}" \
        "${name}" \
        "${github_deploy_key_title}" \
        "${project_git_repo_public_key}" \
        "false"

    echo -e "${green_color}Done!${no_color}"
    echo ""
fi

echo -e "${green_color}Pipeline credentials for project '${name}' generation completed successfully!${no_color}"
