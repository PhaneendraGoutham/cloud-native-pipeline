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
    ./gradlew clean release -Prelease.useAutomaticVersion=true -x test
else
    ./gradlew clean assemble
fi

group_id=$(get_group_id)
group_id_path=$(get_group_id_path)
artifact_id=$(get_artifact_id)

cd build/libs

version=$(get_version_from_artifact_file ${artifact_id})
packaging=jar
generate_pom=true
artifact_file=$(get_artifact_file ${artifact_id})

options="-Durl=${artifact_repo_uri} "
options="${options} -DrepositoryId=${artifact_repo_id} "
options="${options} -DgroupId=${group_id} "
options="${options} -DartifactId=${artifact_id} "
options="${options} -Dversion=${version} "
options="${options} -Dpackaging=${packaging} "
options="${options} -DgeneratePom=${generate_pom} "
options="${options} -Dfile=${artifact_file}"

mvn deploy:deploy-file ${options}
