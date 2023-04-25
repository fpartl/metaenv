#!/bin/bash

### CONFIGURATIONS
INSTALL_PATH=${HOME}
INSTALL_SCRIPTS=(
    ".bash_aliases"
    ".bash_containers"
    ".bash_jobs"
    ".bash_login"
    ".bash_modules"
    ".bash_profile"
    ".bashrc"
)
USER_CONFIG_FILE=".metaenv_user_conf"
VSCODE_INSTALL_PATH="tools/code-cli"

### SCRIPT BODY
success_echo() {
    echo -e "\033[1;32m$1\033[0m"
}

info_echo() {
    echo -e "\033[1;34m$1\033[0m"
}

confirm_prompt() {
    read -p "${1} (y/n) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

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

# Get location of this script
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/src"

# Get installation folder (idealy user's home directory)
# Sets install_path global variable!
get_install_folder "${INSTALL_PATH}" "In which home directory do you want to install scripts?:" 1
if [[ $? -ne 0 ]]; then
    exit 1
fi

# # Prompt user for confirmation
# confirm_prompt "Are you sure you want to proceed?"
# if [[ $? -ne 0 ]]; then
#     echo "See you later then..."
#     exit 1
# fi

# Install user configuration script
echo
info_echo "Installing user configuration file..."

target_config_file="${install_path}/${USER_CONFIG_FILE}"
if [[ -f ${target_config_file} ]]; then
    confirm_prompt "File ${target_config_file} already exists. Are you really sure you want to rewrite it?!"

    if [[ $? -ne 0 ]]; then
        echo "Skipping user configuration file..."
        target_config_file=""
    fi
fi

if [[ ! -z ${target_config_file} ]]; then
    rm -f "${target_config_file}"
    cp "${script_dir}/${USER_CONFIG_FILE}" "${target_config_file}"
fi

# Create symlinks (remove existing symlinks)
echo
info_echo "Creating symlinks..."
for script in ${INSTALL_SCRIPTS[@]}; do
    symlink_name="${install_path}/${script}"
    script_name="${script_dir}/${script}"

    echo "creating ${symlink_name}..."
    if [[ ! -f ${script_name} ]]; then
        echo "This is very weird. Script ${script_name} does not exists... skipping."
        continue
    fi

    if [[ -f ${symlink_name} ]] && [[ ! -L ${symlink_name} ]]; then
        confirm_prompt "File ${symlink_name} already exists. Do you want to rewrite it?"

        if [[ $? -ne 0 ]]; then
            echo "Skipping script \"${script}\"..."
            continue
        fi
    fi

    symlink_dir=$(dirname ${symlink_name})
    if [[ ! -w ${symlink_dir} ]]; then
        mkdir -p ${symlink_dir}
    fi

    rm -f ${symlink_name}
    ln -s ${script_name} ${symlink_name}
    if [[ $? -ne 0 ]]; then
        echo "Symlink creation failed... skipping."
    fi
done

# Install VS Code CLI
echo
info_echo "Installing custom 3rd party software..."
confirm_prompt "Do you want to install VS Code CLI?"
if [[ $? -eq 0 ]]; then
    echo "installing VS Code CLI..."

    # Get install folder for VS Code CLI
    # function sets global variable install_path
    get_install_folder "${install_path}/${VSCODE_INSTALL_PATH}" "In which directory do you want to VS Code CLI?" 0
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

echo
success_echo "Installation completed! Have a nice day!"
