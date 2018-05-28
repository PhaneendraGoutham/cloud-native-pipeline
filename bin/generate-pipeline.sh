#!/usr/bin/env bash

work_dir=$(dirname $0)
source ${work_dir}/shared/colors.sh
source ${work_dir}/shared/commons.sh
source ${work_dir}/config/properties.sh

echo -e "${cyan_color}*************************************************************************${no_color}"
echo -e "${cyan_color}OpenGood.io Cloud-Native App Concourse CI Pipeline Generator${no_color}"
echo -e "${cyan_color}*************************************************************************${no_color}"
echo ""

is_fly_installed=`fly --version`

if [ $(contains ${is_fly_installed} "command not found") == "true" ] ; then
    echo -e "${red_color}Fly CLI is not installed! Please install Fly CLI before continuing.${no_color}"
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

project_dir=${workspace_dir}/${name}
build_dir=${project_dir}/build

project_pipeline_parameters_file=${project_dir}/ci/${pipeline_parameters_file}
generated_pipeline_config_file=${build_dir}/${pipeline_config_file}
generated_pipeline_parameters_file=${build_dir}/${pipeline_parameters_file}

echo -e "Enter value for Concourse CI ${cyan_color}'concourseTeamName' (default: ${default_concourse_team_name})${no_color}, followed by [ENTER]:"
read concourse_team_name
echo ""

if [ "${concourse_team_name}" == "" ] ; then
    concourse_team_name=${default_concourse_team_name}
fi

concourse_team_name=$(replace_special_chars_with_dash "${concourse_team_name}")

echo -e "Does your cloud-native project already have a Fly CLI target saved with Concourse CI credentials?"
echo -e "Enter ${cyan_color}'Y'${no_color} for Yes and ${cyan_color}'N'${no_color} for No or leave blank, followed by [ENTER]:"
read has_target_saved
echo ""

has_target_saved=`echo $(to_upper_case "${has_target_saved}")`

if [ "${has_target_saved}" == "N" ] ; then
    echo -e "Enter value for Concourse CI ${cyan_color}'username' (required)${no_color}, followed by [ENTER]:"
    read concourse_username
    echo ""

    if [ "${concourse_username}" == "" ] ; then
        echo -e "${red_color}ERROR! Concourse CI 'username' not entered! Please try again.${no_color}"
        echo ""
        exit 1
    fi

    echo -e "Enter value for Concourse CI ${cyan_color}'password' (required)${no_color}, followed by [ENTER]:"
    concourse_password=$(read_password_input)
    echo ""

    if [ "${concourse_password}" == "" ] ; then
        echo -e "${red_color}ERROR! Concourse CI 'password' not entered! Please try again.${no_color}"
        echo ""
        exit 1
    fi
else
    concourse_username="Target Saved"
    concourse_password="Target Saved"
fi

echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Pipeline information${no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo ""
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Shared pipeline{no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Project name: ${shared_pipeline_project}${no_color}"
echo -e "${cyan_color} Project dir: ${shared_pipeline_project_dir}${no_color}"
echo -e "${cyan_color} Config file: ${shared_pipeline_config_file}${no_color}"
echo -e "${cyan_color} Params file: ${shared_pipeline_parameters_file}${no_color}"
echo ""
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Project{no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Project name: ${name}${no_color}"
echo -e "${cyan_color} Project dir: ${project_dir}${no_color}"
echo -e "${cyan_color}   Build dir: ${build_dir}${no_color}"
echo ""
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Project pipeline{no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Pipeline name: ${pipeline_name}${no_color}"
echo -e "${cyan_color}  Config file: ${generated_pipeline_config_file}${no_color}"
echo -e "${cyan_color}  Params file: ${generated_pipeline_parameters_file}${no_color}"
echo ""
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Concourse CI{no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo -e "${cyan_color}Team name: ${concourse_team_name}${no_color}"
echo -e "${cyan_color} Username: ${concourse_username}${no_color}"
echo -e "${cyan_color} Password: $(mask_string ${concourse_password})${no_color}"
echo -e "${cyan_color}===================================================================================${no_color}"
echo ""

cd ${workspace_dir}

echo -e "${cyan_color}Deleting build directory '${build_dir}', if it exists, then create it...${no_color}"
rm -rf ${build_dir}
mkdir -p ${build_dir}
echo -e "${green_color}Done!${no_color}"
echo ""

echo -e "${cyan_color}Building Concourse CI pipeline for deployment, if it exists...${no_color}"
cp ${shared_pipeline_config_file} ${generated_pipeline_config_file}
cat ${shared_pipeline_parameters_file} ${project_pipeline_parameters_file} > ${generated_pipeline_parameters_file}
echo -e "${green_color}Done!${no_color}"
echo ""

if [ "${has_target_saved}" == "N" ] ; then
    echo -e "${cyan_color}Authenticating with Concourse CI via Fly...${no_color}"
    is_authenticated=`fly -t ${concourse_instance_name} login -c ${concourse_uri} -n ${concourse_team_name} -u ${concourse_username} -p ${concourse_password} -k`
    echo ${is_authenticated}

    if [ $(contains ${is_authenticated} "target saved") == "false" ] ; then
        echo -e "${red_color}Unable to authenticate with Concourse CI! Please try again.${no_color}"
        echo ""
        exit 1
    fi
    echo -e "${green_color}Done!${no_color}"
    echo ""
fi

echo -e "${cyan_color}Flying pipeline to Concourse CI via Fly...${no_color}"
fly -t ${concourse_instance_name} set-pipeline -p ${name} -c ${generated_pipeline_config_file} -l ${generated_pipeline_parameters_file} -n
fly -t ${concourse_instance_name} expose-pipeline -p ${name}
echo -e "${green_color}Done!${no_color}"
echo ""

echo -e "${cyan_color}Cleaning up...${no_color}"
echo -e "${cyan_color}Deleting build directory '${build_dir}'...${no_color}"
rm -rf ${build_dir}
echo -e "${green_color}Done!${no_color}"
echo ""

echo -e "${green_color}Concourse CI pipeline '${name}' generation completed successfully!${no_color}"
