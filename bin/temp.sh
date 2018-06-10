#!/usr/bin/env bash

source_dir=$(dirname $0)
source ${source_dir}/shared/colors.sh
source ${source_dir}/shared/commons.sh
source ${source_dir}/config/properties.sh

    generate_gpg_keys \
        "${gpg_dir}" \
        "${gpg_key_type}" \
        "${gpg_key_length}" \
        "${gpg_key_usage}" \
        "test" \
        "test" \
        "test" \
        "cjaehnen@me.com" \
        "${gpg_key_expire_date}" \
        "${gpg_key_server}" \
        "${gpg_key_ring_import_file}" \
        "${gpg_passphrase_file}" \
        "${gpg_secret_keys_file}"
    maven_central_gpg_secret_keys=`cat ${gpg_secret_keys_file}`
    echo -e "${maven_central_gpg_secret_keys}"