#!/bin/bash

# Available verbosity levels
AVAIL_VERBOSITY_LEVELS=(
    quiet=0
    error=1
    warning=2
    info=3
    verbose=4
)

# Load user defined configuration arrays
if [[ -f ~/.metaenv_user_conf ]]; then
    . ~/.metaenv_user_conf
fi

# Generate verbosity levels aliases
if [[ ! -z ${AVAIL_VERBOSITY_LEVELS} ]]; then
    for ((i=0; i<${#AVAIL_VERBOSITY_LEVELS[@]}; i++)); do
        IFS='=' read -ra verbosity_line <<< "${AVAIL_VERBOSITY_LEVELS[$i]}"
        echo_fnc_name="echo_${verbosity_line[0]}"
        verbosity_level="${verbosity_line[1]}"

        eval "${echo_fnc_name}() {
            if [[ ${VERBOSITY_LEVEL} -ge ${verbosity_level} ]]; then
                echo \"\$@\"
            fi
        }"
    done
fi
