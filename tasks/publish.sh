#!/bin/bash
set -e -x -u

cd source

if [ "${env}" == "release" ] ; then
    ./gradlew clean release -Prelease.useAutomaticVersion=true -x test
else
    ./gradlew clean assemble
fi

if [ -d "${project_dir}" ]; then
    cd ${project_dir}
fi

echo ${artifact_repo_signing_key_secret_keys} > secret-keys.gpg

echo "nexusUsername=${artifact_repo_username}" > gradle.properties
echo "nexusPassword=${artifact_repo_password}" >> gradle.properties
echo "signing.keyId=${artifact_repo_signing_key_id}" >> gradle.properties
echo "signing.password=${artifact_repo_signing_key_passphrase}" >> gradle.properties
echo "signing.secretKeyRingFile=secret-keys.gpg" >> gradle.properties

if [ -d "${project_dir}" ]; then
    ${get_cd_up_path ${project_dir}}gradlew uploadArchives
else
    ./gradlew uploadArchives
fi
