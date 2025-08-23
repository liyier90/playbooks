#!/usr/bin/env bash

set -euo pipefail
[[ "${TRACE:-0}" == "1" ]] && set -x

export PIP_INDEX_URL='https://pypi.org/simple'

pyenv_installer_url='https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer'
pyenv_mpdecimal_version='4.0.1'
pyenv_mpdecimal_url="https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-${pyenv_mpdecimal_version}.tar.gz"
pyenv_python_version='3.11'

uv_version='0.8.13'
uv_installer_url="https://github.com/astral-sh/uv/releases/download/${uv_version}/uv-installer.sh"

# ansible_env="${ANSIBLE_ENV:-ansible}"

log() {
    local level="${1}"
    local message="${2}"
    printf '%s - %s - %s\n' "${level}" "$(date +%Y%m%d-%H%M%S)" "${message}"
}

log_error() {
    log 'ERROR' "${1}"
    exit 1
}

log_info() {
    log 'INFO' "${1}"
}

###############
# Install pyenv
###############
log_info 'BEGIN Install pyenv'
pushd .

pyenv_installer=$(curl -fsSL "${pyenv_installer_url}")
if [[ -z "${pyenv_installer}" ]]; then
    log_error 'Empty script'
fi
bash <<<"${pyenv_installer}"

export PYENV_ROOT="${HOME}/.pyenv"
[[ -d "${PYENV_ROOT}/bin" ]] && export PATH="${PYENV_ROOT}/bin${PATH:+:${PATH}}"
eval "$(pyenv init - bash)"
eval "$(pyenv virtualenv-init -)"

log_info "$(pyenv --version)"

popd
log_info 'END Install pyenv'

################
# Install Python
################
log_info "BEGIN Install Python ${pyenv_python_version}"

log_info '  BEGIN Install dependencies'

sudo apt-get update
sudo apt-get install -yq \
    build-essential \
    ccache \
    cmake \
    gdb \
    lcov \
    libb2-dev \
    libbz2-dev \
    libffi-dev \
    libgdbm-compat-dev \
    libgdbm-dev \
    liblzma-dev \
    libncurses5-dev \
    libreadline6-dev \
    libsqlite3-dev \
    libssl-dev \
    libzstd-dev \
    lzma \
    lzma-dev \
    pkg-config \
    strace \
    tk-dev \
    uuid-dev \
    xvfb \
    zlib1g-dev

log_info '    BEGIN Install mpdecimal'
pushd .

mkdir /tmp/mybuild
cd /tmp/mybuild

wget "${pyenv_mpdecimal_url}"
tar -xvf mpdecimal-*.tar.gz 
cd mpdecimal-*/

./configure --prefix='/usr/local'
make -j
sudo make install

rm -rf /tmp/mybuild

popd
log_info '    END Install mpdecimal'

log_info '  END Install dependencies'

export MAKE_OPTS='-j'
pyenv install "${pyenv_python_version}"
unset MAKE_OPTS

log_info "END Install Python ${pyenv_python_version}"

############
# Install uv
############
log_info 'BEGIN Install uv'

uv_installer=$(curl -fsSL "${uv_installer_url}")
if [[ -z "${uv_installer}" ]]; then
    log_error 'Empty script'
fi
bash <<<"${uv_installer}"

local_root="${HOME}/.local"
[[ -d "${local_root}/bin" ]] && export PATH="${local_root}/bin${PATH:+:${PATH}}"

log_info "$(uv --version)"

log_info 'END Install uv'

##########################
# Configure Python Mirrors
##########################
log_info 'BEGIN Configure Python Mirrors'
log_info "Set pip index URL=${PIP_INDEX_URL}"

uv_config_dir="${HOME}/.config/uv" 
[[ -d "${uv_config_dir}" ]] || mkdir -p "${uv_config_dir}"
envsubst < files/uv.toml.template >> "${uv_config_dir}/uv.toml"

pip_config_dir="${HOME}/.pip"
[[ -d "${pip_config_dir}" ]] || mkdir -p "${pip_config_dir}"
envsubst < files/pip.conf.template >> "${pip_config_dir}/pip.conf"

log_info 'END Configure Python Mirrors'

#################
# Install Ansible
#################
log_info 'BEGIN Install Ansible'

uv sync --frozen
uv run ansible-galaxy install -f -r requirements.yml

log_info 'END Install Ansible'
