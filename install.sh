#!/bin/bash

### CONFIGURATIONS
INSTALL_PATH=${HOME}
INSTALL_SCRIPTS=(
    ".bash_functions"
    ".bash_login"
    ".bash_modules"
    ".bash_profile"
    ".bashrc"
)
USER_CONFIG_FILE=".metaenv_user_conf"

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

# Get location of this script
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/src"

# Get installation folder (idealy user's home directory)
while true; do
    install_path=${INSTALL_PATH}

    read \
        -p "In which home directory do you want to install scripts? (${install_path}):" \
        user_install_path

    if [[ ! -z ${user_install_path} ]]; then
        install_path=${user_install_path}
    fi

    if [[ -w ${install_path} ]]; then
        break
    else
        echo "Directory \"${install_path}\" does not exist or it is not writable! Restarting..."
    fi
done

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

    if [[ -f ${symlink_name} ]]; then
        confirm_prompt "File ${symlink_name} already exists. Do you want to rewrite it?"
        if [[ $? -ne 0 ]]; then
            echo "Skipping script \"${script}\"..."
            continue
        else
            rm -f ${symlink_name}
        fi
    fi

    symlink_dir=$(dirname ${symlink_name})
    if [[ ! -w ${symlink_dir} ]]; then
        mkdir -p ${symlink_dir}
    fi

    ln -s ${script_name} ${symlink_name}
    if [[ $? -ne 0 ]]; then
        echo "Symlink creation failed... skipping."
    fi
done

echo
success_echo "Installation completed! Have a nice day!"
