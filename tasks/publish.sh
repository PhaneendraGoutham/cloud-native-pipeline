#!/bin/bash
set -e -x -u

work_dir=$(dirname $0)
source ${work_dir}/shared/commons.sh

cd source

if [ "${env}" == "release" ] ; then
    ./gradlew clean release -Prelease.useAutomaticVersion=true -x test
else
    ./gradlew clean assemble
fi

if [ -d "${project_dir}" ]; then
    cd ${project_dir}

    configure_artifact_publishing \
        ${artifact_repo_username} \
        ${artifact_repo_password} \
        ${artifact_repo_signing_key_id} \
        ${artifact_repo_signing_key_passphrase} \
        ${artifact_repo_signing_key_secret_keys}

    $(get_cd_up_path ${project_dir})gradlew uploadArchives
else
    configure_artifact_publishing \
        ${artifact_repo_username} \
        ${artifact_repo_password} \
        ${artifact_repo_signing_key_id} \
        ${artifact_repo_signing_key_passphrase} \
        ${artifact_repo_signing_key_secret_keys}

    ./gradlew uploadArchives
fi
