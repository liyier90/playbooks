#!/usr/bin/env bash

set -euo pipefail
[[ "${TRACE:-0}" == "1" ]] && set -x

conda_base_prefix="${CONDA_BASE_PREFIX:-${HOME}/conda}"
ansible_env="${ANSIBLE_ENV:-ansible}"

log_info() {
    local message=$1
    printf 'INFO - %s - %s\n' $(date +%Y%m%d-%H%M%S) "${message}"
}

###################
# Install Miniforge
###################
log_info 'Started Miniforge install'
pushd .

mkdir /tmp/mybuild
cd /tmp/mybuild
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
chmod +x ./Miniforge3-*.sh
./Miniforge3-*.sh -b -p "${conda_base_prefix}"
rm -rf /tmp/mybuild

popd
log_info 'Finished Miniforge install'

#################
# Install Ansible
#################
log_info 'Started Ansible install'

. "${conda_base_prefix}/etc/profile.d/conda.sh"
conda env create -n "${ansible_env}" -f ansible.yml

log_info 'Finished Ansible install'
