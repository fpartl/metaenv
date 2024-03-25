#!/bin/bash

# Loading modules from INITIALIZED_MODULES array (defined in `.metaenv_user_conf` file)
if [[ ! -z ${INITIALIZED_MODULES} ]]; then
    echo_info -e "\nAdding modules..."

    for module in ${INITIALIZED_MODULES[@]}; do
        echo_verbose -n "adding \`${module}\`... "

        # Remove module first to avoid conflicts (because module is a piece of shit...)
        module rm ${module} >/dev/null 2>&1
        module add ${module} >/dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            echo_verbose -e "\033[0;32mok\033[0m"
        else
            echo_verbose -e "\033[0;31mnok!\033[0m"
        fi
    done
fi

# Base conda environment with some useful packages
enco() {
    if ! command -v conda &> /dev/null; then
        echo_error -e "\033[0;32mRun `module add conda-modules` first!\033[0m"
        return 1
    fi

    echo_info "Activating conda env ${BASE_CONDA_ENV_NAME}..."

    base_conda_env_exitsts=$(conda env list -q | grep $BASE_CONDA_ENV_NAME | wc -l)
    if [[ $base_conda_env_exitsts -ne 1 ]]; then
        echo_info "Conda env ${BASE_CONDA_ENV_NAME} does not exists... creating now!"

        conda create \
            --name $BASE_CONDA_ENV_NAME \
            --no-default-packages \
            python=$BASE_CONDA_ENV_PYTHON

        conda activate $BASE_CONDA_ENV_NAME

        # Install packages from BASE_CONDA_ENV_PACKAGES
        if [[ ! -z ${BASE_CONDA_ENV_PACKAGES} ]]; then
            for package in ${BASE_CONDA_ENV_PACKAGES[@]}; do
                pip install "${package}"
            done
        fi
    else
        conda activate $BASE_CONDA_ENV_NAME
    fi
}
