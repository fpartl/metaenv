#!/bin/bash

### CONFIGURATIONS
INSTALL_PATH=${HOME}
INSTALL_SCRIPTS=(
    ".bash_functions"
    ".bash_login"
    ".bash_modules"
    ".bash_profile"
    ".bashrc"
    ".ssh/config"
)

### SCRIPT BODY
confirm_prompt() {
    read -p "${1} (y/n) " -n 1 -r; echo
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

# Prompt user for confirmation
confirm_prompt "Are you sure you want to proceed?"
if [[ $? -ne 0 ]]; then
    echo "See you later then..."
    exit 1
fi

# Create symlinks (remove existing symlinks)
echo "Creating symlinks now..."
for script in ${INSTALL_SCRIPTS[@]}; do
    symlink_name="${INSTALL_PATH}/${script}"
    script_name="${script_dir}/${script}"

    confirm_prompt "Create symlink \"${symlink_name} -> ${script_name}\"?"
    if [[ $? -ne 0 ]]; then
        echo "Skipping script \"${script}\"..."
        continue
    fi

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
        continue
    fi
done

echo "Installation completed! Have a nice day!"
