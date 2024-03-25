#!/bin/bash

# Rewrite environment variables
if [[ ! -z ${ENVIRONMENT_VARS} ]]; then
    echo_info -e "\nExporting environment variables..."

    for ((i=0; i<${#ENVIRONMENT_VARS[@]}; i++)); do
        IFS='=' read -ra var_line_arr <<< "${ENVIRONMENT_VARS[$i]}"
        var_name="${var_line_arr[0]}"
        var_value="${var_line_arr[1]}"

        echo_verbose -n "exporting ${var_name}=\"${var_value}\"... "
        export ${var_name}="${var_value}"

        if [[ ${!var_name} == ${var_value} ]]; then
            echo_verbose -e "\033[0;32mok\033[0m"
        else
            echo_verbose -e "\033[0;31mnok!\033[0m"
        fi
    done
fi

# Add your software to PATH
if [[ ! -z ${EXTRA_PATH_DIRS} ]]; then
    echo_info -e "\nAdding items to PATH variable..."

    for ((i=0; i<${#EXTRA_PATH_DIRS[@]}; i++)); do
        echo_verbose -n "adding \"${EXTRA_PATH_DIRS[$i]}\"... "
        export PATH="${EXTRA_PATH_DIRS[$i]}:${PATH}"

        if [[ "${PATH}" == *"${path}"* ]]; then
            echo_verbose -e "\033[0;32mok\033[0m"
        else
            echo_verbose -e "\033[0;31mnok!\033[0m"
        fi
    done
fi