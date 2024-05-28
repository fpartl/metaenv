#!/bin/bash

### CONFIGURATIONS

### SCRIPT BODY
success_echo() {
    echo -e "\033[1;32m$1\033[0m"
}

warning_echo() {
    echo -e "\033[1;33m$1\033[0m"
}

info_echo() {
    echo -e "\033[1;34m$1\033[0m"
}

confirm_prompt() {
    read -p "${1} (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Get metaenv home dir (where this script is located)
METAENV_SRC_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/src"

# $1 default path
# $2 prompt
# $3 has to be writable
install_path=""
get_install_folder() {
    while true; do
        install_path="${1}"

        read -p "${2} (${1}): " user_path
        if [[ ! -z ${user_path} ]]; then
            install_path=${user_path}
        fi

        if [[ -w ${install_path} ]] || [[ $3 -eq 0 ]]; then
            break
        else
            echo "Directory \"${install_path}\" does not exist or it is not writable! Restarting..."
        fi
    done
}


# Get installation folder (idealy user's home directory)
# Sets install_path global variable!
INSTALL_PATH=${HOME}
get_install_folder "${INSTALL_PATH}" "For which home directory do you want to install metaenv?" 1
if [[ $? -ne 0 ]]; then
    exit 1
fi
metaenv_install_path="${install_path}"

# Install Metacentrum recommendations scripts!
# Copy all ".bash*" files from `METAENV_SRC_DIR/src/meta_ref` to install_path (promt user if file already exists)
echo
info_echo "Installing Metacentrum recommendations scripts..."
warning_echo "Please note that this will overwrite your existing \`~/.bash*\` files! Skip this step or backup your files first!"
meta_ref_dir="${METAENV_SRC_DIR}/meta_ref"
for file in ${meta_ref_dir}/.bash*; do
    target_file="${metaenv_install_path}/$(basename ${file})"

    if [[ -f ${target_file} ]]; then
        confirm_prompt "File \`${target_file}\` already exists. Do you want to rewrite it?"

        if [[ $? -ne 0 ]]; then
            echo "Skipping file \"$(basename ${file})\"..."
            continue
        fi
    fi

    cp ${file} ${target_file}
done
success_echo "OK!"


# Install Metaenv user configuration script
echo
info_echo "Installing Metaenv user configuration file..."
USER_CONFIG_FILE=".metaenv_user_conf"
target_config_file="${metaenv_install_path}/${USER_CONFIG_FILE}"
if [[ -f ${target_config_file} ]]; then
    confirm_prompt "File \`${target_config_file} already exists. Are you really sure you want to rewrite it?!"

    if [[ $? -ne 0 ]]; then
        echo "Skipping user configuration file..."
        target_config_file=""
    fi
fi
if [[ ! -z ${target_config_file} ]]; then
    cp "${METAENV_SRC_DIR}/${USER_CONFIG_FILE}" "${target_config_file}"
fi
success_echo "OK!"


# Add block to user's .bashrc file (source scripts from `INSTALL_SCRIPTS` array)
# Rewrite exising source block if exists (decorate using `# metaenv` comment)
INSTALL_SCRIPTS=(
    "metaenv.sh"
    "env_vars.sh"
    "aliases.sh"
    "modules.sh"
    "containers.sh"
    "jobs.sh"
)
BASHRC_FILE="${metaenv_install_path}/.bashrc"
SOURCE_BLOCK_DELIMITER="# metaenv stuff"

echo
info_echo "Adding metaenv sources to your \`${BASHRC_FILE}\`..."

# create source block
source_block="${SOURCE_BLOCK_DELIMITER} \n"
for script in ${INSTALL_SCRIPTS[@]}; do
    source_block="${source_block}source ${METAENV_SRC_DIR}/${script}\n"
done
source_block="${source_block}${SOURCE_BLOCK_DELIMITER}"

# add source block to user's `.bashrc` file
if grep -q "${SOURCE_BLOCK_DELIMITER}" ${BASHRC_FILE}; then
    sed -i "/${SOURCE_BLOCK_DELIMITER}/,/${SOURCE_BLOCK_DELIMITER}/d" ${BASHRC_FILE}
fi
echo -e "\n${source_block}" >> ${BASHRC_FILE}
success_echo "OK!"

# Install custom 3rd party software
echo
info_echo "Installing custom 3rd party software..."

# Install VS Code CLI
VSCODE_INSTALL_PATH="tools/code-cli"

confirm_prompt "Do you want to install VS Code CLI?"
if [[ $? -eq 0 ]]; then
    echo "Installing VS Code CLI..."

    # Get install folder for VS Code CLI
    # function sets global variable install_path
    get_install_folder "${metaenv_install_path}/${VSCODE_INSTALL_PATH}" "In which directory do you want to VS Code CLI?" 0
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    mkdir -p "${install_path}"
    if [[ $? -ne 0 ]]; then
        echo_error "Error while creating ${install_path} folder..."
        exit 1
    fi

    cd "${install_path}"
    curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz &> /dev/null
    tar -xf vscode_cli.tar.gz
    rm -f vscode_cli.tar.gz

    vscode_path="${install_path}/code"
    if [[ ! -x "${vscode_path}" ]]; then
        echo_error "VS Code CLI was not successful... check https://code.visualstudio.com/docs/remote/tunnels for more details."
        exit 1
    fi

    # Add install_path to PATH array
    sed -i "/^EXTRA_PATH_DIRS=(.*/a \ \ \ \ \"${install_path}\" # vscode-cli installation folder" "${target_config_file}"
fi


# Install Conda
MINICONDA_INSTALL_PATH="tools/miniconda"

echo
info_echo "Installing Miniconda..."
confirm_prompt "Do you want to install Miniconda?"
if [[ $? -eq 0 ]]; then
    echo "installing Miniconda..."

    # Get install folder for Miniconda
    # function sets global variable install_path
    get_install_folder "${metaenv_install_path}/${MINICONDA_INSTALL_PATH}" "In which directory do you want to install Miniconda?" 0
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    mkdir -p "${install_path}"
    if [[ $? -ne 0 ]]; then
        echo_error "Error while creating ${install_path} folder..."
        exit 1
    fi

    cd "${install_path}"
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -u -p "${install_path}"
    rm -f miniconda.sh

    # initialize conda
    "${install_path}/bin/conda" init bash
fi

echo
success_echo "Installation completed! Have a nice day!"

