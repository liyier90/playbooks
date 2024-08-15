#!/usr/bin/env bash

set -euo pipefail
[[ "${TRACE:-0}" == "1" ]] && set -x

conda_base_prefix="${CONDA_BASE_PREFIX:-${HOME}/conda}"
ansible_env="${ANSIBLE_ENV:-ansible}"

log_info() {
    local message=$1
    printf 'INFO - %s - %s\n' "$(date +%Y%m%d-%H%M%S)" "${message}"
}

###################
# Install Miniforge
###################
log_info 'Started Miniforge install'
pushd .

mkdir /tmp/mybuild
cd /tmp/mybuild
miniforge_installer="Miniforge3-$(uname)-$(uname -m).sh"
wget "https://github.com/conda-forge/miniforge/releases/latest/download/${miniforge_installer}"
chmod +x "${miniforge_installer}"
"./${miniforge_installer}" -b -p "${conda_base_prefix}"
[[ -f "{conda_base_prefix}/.condarc" ]] && rm "${conda_base_prefix}/.condarc"
rm -rf /tmp/mybuild

popd
log_info 'Finished Miniforge install'

##########################
# Configure Python Mirrors
##########################
log_info 'Started configuring Python Mirrors'
log_info "Set conda channel URL=${CONDA_CHANNEL_URL}"
log_info "Set pip index URL=${PIP_INDEX_URL}"

envsubst < files/condarc.template >> ~/.condarc

[[ -d ~/.pip ]] || mkdir -p ~/.pip
envsubst < files/pipconf.template >> ~/.pip/pip.conf

log_info 'Finished configuring Python Mirrors'

#################
# Install Ansible
#################
log_info 'Started Ansible install'

# shellcheck source=/dev/null
. "${conda_base_prefix}/etc/profile.d/conda.sh"
conda env create -n "${ansible_env}" -f ansible.yml
conda activate "${ansible_env}"
ansible-galaxy install -f -r requirements.yml

log_info 'Finished Ansible install'
