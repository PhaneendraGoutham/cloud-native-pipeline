#!/bin/bash
set -e -x -u

ssh_dir=~/.ssh
ssh_key_temp_file=${ssh_dir}/key_temp_file
ssh_key_file=${ssh_dir}/key_file
ssh_known_hosts_file=${ssh_dir}/known_hosts

mkdir -p ${ssh_dir}

echo ${github_private_key} > ${ssh_key_temp_file}
sed s/-----BEGIN\sRSA\sPRIVATE\sKEY-----\s//g ${ssh_key_temp_file} -i
sed s/\s-----END\sRSA\sPRIVATE\sKEY-----//g ${ssh_key_temp_file} -i
sed s/\s/\n/g ${ssh_key_temp_file} -i
echo "-----BEGIN RSA PRIVATE KEY-----" > ${ssh_key_file}
cat ${ssh_key_temp_file} >> ${ssh_key_file}
echo "-----END RSA PRIVATE KEY-----" >> ${ssh_key_file}

rm ${ssh_key_temp_file}
chmod 600 ${ssh_key_file}

ssh-keyscan ${github_host} >> ${ssh_known_hosts_file}
cat ${ssh_known_hosts_file}

ps -p ${SSH_AGENT_PID} > /dev/null || eval "$(ssh-agent -s)"
ssh-add ${ssh_key_file}

git config --global user.name "${git_user}"
git config --global user.email "${git_email}"
