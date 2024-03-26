#!/bin/bash

# TODO: Dockerfile->Singularity def file if a nice idea, but it's not working because of INCLUDE+ command in Dockerfiles

# Compile Docker image to Singularity image
docker-to-sif() {
    docker_image=$([[ -r $1 ]] && echo $1 || echo "")
    singul_image=$([[ -z $2 ]] && echo "${docker_image}.sif" || echo $2 )

    # Check if input file exists
    if [[ -z $docker_image ]]; then
        echo_error "docker-to-sif <docker-image-file> [singularity-output-sif]"
        return 1
    fi

    temp_docker_image="${docker_image}"
    temp_singul_image="${singul_image}"

    # Use machine's $SCRATCHDIR if available!
    if [[ $SCRATCHDIR != "/scratch/${USER}" ]]; then
        tmp-to-scratch

        read -p "SCRATCHDIR is available. Do you want to use it? (y/n):" -n 1 -r
        echo

        if [[ $REPLY =~ ^y|Y$ ]]; then
            echo_info -e "\n\033[1;34mUsing machines \$SCRATCHDIR (\`${SCRATCHDIR}\`)...\033[0m"

            # Ready scratch dir for image copies
            scratch_temp="${SCRATCHDIR}/docker-to-sif-temp"
            rm -rf "${scratch_temp}"
            mkdir -p "${scratch_temp}"

            # Copy Docker image
            image_name=$(basename "${docker_image}")
            temp_docker_image="${scratch_temp}/${image_name}"
            echo_info "Copying Docker image to \`${temp_docker_image}\`..."
            rsync -ah --info=progress2 --info=name0 "${docker_image}" "${temp_docker_image}"

            # Set temp singularity image
            image_name=$(basename "${singul_image}")
            temp_singul_image="${scratch_temp}/${image_name}"
        fi
    fi

    # Build singularity image
    echo_info -e "\n\033[1;34mRunning \`singularity build\` command...\033[0m"
    singularity build "${temp_singul_image}" "docker-archive://${temp_docker_image}"
    build_ret=$?

    # Copy singularity image to target destination and remove temp image
    if [[ $build_ret -eq 0 ]] && [[ "${singul_image}" != "${temp_singul_image}" ]]; then
        echo_info "Copying singularity image to target destination..."
        rsync -ah --info=progress2 --info=name0 "${temp_singul_image}" "${singul_image}"
        rm -rf "${scratch_temp}"
    fi

    # Print build info
    if [[ $build_ret -eq 0 ]]; then
        echo_info -e "\033[0;32mRun with: singularity shell $(realpath $singul_image)\033[0m"
    else
        echo_error -e "\033[0;31mError while running \`singularity build\` command...\033[0m" 
    fi
}

sinshell() {
    # Possible destinations for singularity image (in order of priority)
    possible_images=(
        "${1}"
        "$(find . -maxdepth 1 -type f -name "*.sif" 2>/dev/null | head -n 1)"
        "$(find singularity -maxdepth 1 -type f -name "*.sif" 2>/dev/null | head -n 1)"
        "$(find build -maxdepth 1 -type f -name "*.sif" 2>/dev/null | head -n 1)"
    )

    # Check if any of the possible destinations exists
    for image in "${possible_images[@]}"; do
        if [[ -f "${image}" ]]; then
            echo_info "Using singularity image \`${image}\`..."
            singul_image="${image}"
            break
        fi
    done

    # Check if any singularity image was found
    if [[ -z "${singul_image}" ]]; then
        echo_error "sinshell [sif-image] ... if [sif-image] is not provided \`sinshell\` will search \`*.sif\` files in \`.\` and \`singularity\` directories."
        return 1
    fi

    # Check if SCRATCHDIR is available
    scratchdir_bind=$([[ "${SCRATCHDIR}" != "/scratch/${USER}" ]] && echo "-B \"${SCRATCHDIR}\"" || echo "" )

    # Check if VS Code server is installed and print alias
    vscode_alias="$(alias vscode-server)" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo; echo_info -e "\033[1;34mDefine \`vscode-server\` alias with:\033[0m"
        alias vscode-server
    fi

    # Run singularity shell
    echo
    singularity shell --home "${HOME}" --nv ${scratchdir_bind} "${singul_image}"
}
