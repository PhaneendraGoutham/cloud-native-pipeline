#!/usr/bin/env bash

work_dir=$(dirname $0)
source ${work_dir}/shared/colors.sh
source ${work_dir}/shared/commons.sh
source ${work_dir}/config/properties.sh

echo -e "${cyan_color}*************************************************************************${no_color}"
echo -e "${cyan_color}OpenGood.io Cloud-Native App Concourse CI Pipeline Credentials Generator${no_color}"
echo -e "${cyan_color}*************************************************************************${no_color}"

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

concourse_team_name=$(replace_special_chars_with_dash "${concourse_team_name}")

echo -e "Does your cloud-native project need to publish its own Docker image(s)?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_docker
echo ""

has_docker=`echo $(to_upper_case "${has_docker}")`

if [ "${has_docker}" == "Y" ] ; then
    echo -e "Does your cloud-native project share previously set up Docker credentials?"
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

echo -e "Does your cloud-native project reside on PCF?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_pcf
echo ""

has_pcf=`echo $(to_upper_case "${has_pcf}")`

if [ "${has_pcf}" == "Y" ] ; then
    echo -e "Does your cloud-native project share previously set up PCF credentials?"
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

    echo -e "Does your cloud-native project share a previously set up PCF API endpoint, organization, and space?"
    echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
    read has_pcf_api_org_space
    echo ""

    has_pcf_api_org_space=`echo $(to_upper_case "${has_pcf_api_org_space}")`

    if [ "${has_pcf_api_org_space}" == "N" ] ; then
        echo -e "Enter value for ${cyan_color}'pcfApiEndpoint' (required)${no_color}, followed by [ENTER]:"
        read pcf_api_endpoint
        echo ""

        if [ "${pcf_api_endpoint}" == "" ] ; then
            echo -e "${red_color}ERROR! 'pcfApiEndpoint' not entered! Please try again.${no_color}"
            echo ""
            exit 1
        fi
    fi
else
    pcf_username=""
    pcf_password=""
fi

echo -e "Does your cloud-native project have a database?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_db
echo ""

has_db=`echo $(to_upper_case "${has_db}")`

if [ "${has_db}" == "Y" ] ; then
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

echo -e "Enter value for ${cyan_color}'githubEmail' (required)${no_color}, followed by [ENTER]:"
read github_email
echo ""

if ! [[ ${github_email} =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
    echo -e "${red_color}ERROR! GitHub email address in NOT form [[A-Za-Z][0-9]@[A-Za-Z][0-9].[A-Za-Z][0-9]] (i.e. user@domain.com)! Please try again.${no_color}"
    exit 1
fi

echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Pipeline credentials information${no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}         Pipeline name: ${pipeline_name}${no_color}"
echo -e "${cyan_color}Concourse CI team name: ${concourse_team_name}${no_color}"
echo -e "${cyan_color}       Docker username: ${docker_username}${no_color}"
echo -e "${cyan_color}       Docker password: $(mask_string ${docker_password})${no_color}"
echo -e "${cyan_color}          PCF username: ${pcf_username}${no_color}"
echo -e "${cyan_color}          PCF password: $(mask_string ${pcf_password})${no_color}"
echo -e "${cyan_color}           DB username: ${db_username}${no_color}"
echo -e "${cyan_color}           DB password: $(mask_string ${db_password})${no_color}"
echo -e "${cyan_color}          GitHub email: ${github_email}${no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo ""

ssh_private_key_file=${ssh_dir}/${name}_rsa
ssh_public_key_file=${ssh_dir}/${name}_rsa.pub

echo -e "${cyan_color}Generating SSH private and public keys for GitHub repo deploy key using GitHub email address '${github_email}'...${no_color}"
sudo mkdir -p ${ssh_dir}
cd ${ssh_dir}
ssh-keygen -t rsa -b ${ssh_key_size} -C ${github_email} -f ${ssh_private_key_file} -N ""
eval "$(ssh-agent -s)"
ssh-add -K ${ssh_private_key_file}

while IFS='' read -r line || [[ -n "$line" ]]; do
    private_key="${private_key}  $line\n"
done < ${ssh_private_key_file}

echo -e "${green_color}Done!${no_color}"
echo ""

if [ "${docker_username}" != "" ] && [ "${docker_password}" != "" ] ; then
    echo -e "${cyan_color}Storing Docker shared credentials into Vault for Concourse CI pipeline...${no_color}"
    vault write concourse/${concourse_team_name}/docker-username value=${docker_username}
    vault write concourse/${concourse_team_name}/docker-password value=${docker_password}
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

echo -e "${cyan_color}Storing GitHub private key for GitHub deploy key into Vault...${no_color}"
vault kv put concourse/${concourse_team_name}/${pipeline_name}/github-private-key cert=${ssh_private_key_file}
echo -e "${green_color}Done!${no_color}"
echo ""

if [ -d "${project_dir}/ci" ]; then
    echo -e "${cyan_color}Generating pipeline credentials file '${pipeline_credentials_file}'...${no_color}"
    cd ${project_dir}/ci
    rm -rf ${pipeline_credentials_file}
    echo "---" > ${pipeline_credentials_file}
    echo "docker-username: ${docker_username}" >> ${pipeline_credentials_file}
    echo "docker-password: ${docker_password}" >> ${pipeline_credentials_file}
    echo "pcf-username: ${pcf_username}" >> ${pipeline_credentials_file}
    echo "pcf-password: ${pcf_password}" >> ${pipeline_credentials_file}
    echo "db-username: ${db_username}" >> ${pipeline_credentials_file}
    echo "db-password: ${db_password}" >> ${pipeline_credentials_file}
    echo "github-private-key: |" >> ${pipeline_credentials_file}
    echo -e "${private_key}" >> ${pipeline_credentials_file}
    echo -e "${green_color}Done!${no_color}"
    echo ""
fi

echo -e "${cyan_color}Outputting SSH public key for GitHub repo deploy key...${no_color}"
public_key=`cat ${ssh_public_key_file}`
echo ${public_key}
echo -e "${green_color}Done!${no_color}"
echo ""

echo -e "${green_color}Pipeline credentials for project '${name}' generation completed successfully!${no_color}"
