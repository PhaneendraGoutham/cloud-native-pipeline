#!/bin/bash
set -e -x -u

work_dir=$(dirname $0)
source ${work_dir}/shared/commons.sh

cd source

echo ${artifact_repo_signing_key_secret_keys} >> secret-keys.gpg

echo "nexusUsername=${artifact_repo_username}" >> gradle.properties
echo "nexusPassword=${artifact_repo_password}" >> gradle.properties
echo "signing.keyId=${artifact_repo_signing_key_id}" >> gradle.properties
echo "signing.password=${artifact_repo_signing_key_passphrase}" >> gradle.properties
echo "signing.secretKeyRingFile=secret-keys.gpg" >> gradle.properties

if [ "${env}" == "release" ] ; then
    ./gradlew clean release -Prelease.useAutomaticVersion=true uploadArchives -x test
else
    ./gradlew clean assemble uploadArchives
fi
