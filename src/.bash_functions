#!/bin/bash

# Enable SCRATCH->TMP mapping
alias tmp-to-scratch='export TMPDIR=$SCRATCHDIR'

# Run VS Code server
if command -v code &> /dev/null; then
    alias vscode-server="code tunnel --log trace --verbose"
fi

# Compile Singularity images from docker images
docker-to-sif() {
    docker_image=$([[ -f $1 ]] && echo $1 || echo "")
    singul_image=$([[ -z $2 ]] && echo "${docker_image}.sif" || echo $2 )

    # Check if input file exists
    if [[ -z $docker_image ]]; then
        echo_error "docker-to-sif <docker-image-file> [singularity-output-sif]"
        return 1
    fi

    # Set $SCRATCHDIR to $TMPDIR if scratchdir is available
    if [[ $SCRATCHDIR != "/scratch/${USER}" ]]; then
        tmp-to-scratch
    fi

    # Build singularity image
    singularity build "${singul_image}" "docker-archive://${docker_image}"

    echo_info "Run with: singularity shell $(realpath $singul_image)"
}

watch_job() {
    # Check input arguments
    if [[ -z "${1}" ]] || [[ ! "${2}" =~ ^(ER|OU)$ ]]; then
        echo_error "watch_job <job-id> <ER|OU>"
        return 1
    fi

    # Get job status using `qstat` command (including nonrunning jobs)
    qstat_output=$(qstat -fx -F dsv "${1}" 2>&1)

    # Check if job exists
    job_exists=$(echo "${qstat_output}" | grep "qstat: Unknown Job Id" | wc -l)
    if [[ $job_exists -ne 0 ]]; then
        echo_error "qstat: Unknown Job Id ${1}"
        echo_info "Check may check your jobs at: https://metavo.metacentrum.cz/pbsmon2/user/${USER}"
        return 2
    fi

    # Get job information
    job_id=$(echo "${qstat_output}" | perl -n -e'/Job Id: (.*?)\|/gm && print $1')
    job_state=$(echo "${qstat_output}" | perl -n -e'/job_state=(.*?)\|/gm && print $1')

    # Omit moved jobs
    if [[ $job_state == "M" ]]; then
        qstat_output=$(qstat -f -F dsv "${1}" 2>&1)
    fi

    ### Job is currently runnning
    if [[ $job_state == "R" ]]; then
        echo_info -e "Info: job_state=\033[1;32m\"${job_state}\"\033[0m"

        # Get execution node
        exec_host=$(echo "${qstat_output}" | perl -n -e'/exec_host=(.*?)\//gm && print $1')
        if [[ -z $exec_host ]]; then
            echo_error "Failed to get the execution node... weird."
            return 3
        fi

        # Assemble spool file path
        out_file="/var/spool/pbs/spool/${job_id}.${2}"

        # Run `tail` command over ssh
        echo_info -e "Info: exec_host=\033[1;34m\"${exec_host}\"\033[0m"
        ssh \
            "${exec_host}" \
            "echo && echo -e \"\033[1;34mTail of ${exec_host}:${out_file}:\033[0m\" && tail -f ${out_file}"

        echo
    ### Job is currently not running
    else
        echo_info -e "Info: job_state=\033[1;31m\"${job_state}\"\033[0m"

        # Get output file location
        out_file_key=$([[ $2 == "OU" ]] && echo "Output_Path" || echo "Error_Path")
        out_file=$(echo "${qstat_output}" | perl -n -e"/${out_file_key}=(.*?)\|/gm && print \$1" | cut -f2 -d":")

        # Check if output file actually exists
        if [[ ! -r "${out_file}" ]]; then
            file_type=$([[ $2 == "OU" ]] && echo "Output" || echo "Error")
            echo_error "${file_type} file ${out_file} does not exist!"
            return 4
        fi

        # Run `less` command
        echo -e "\033[1;34mLess of ${out_file}:\033[0m"
        less "${out_file}"

        echo
    fi
}

watch_job_err() {
    if [[ -z "${1}" ]]; then
        echo_error "watch_job_err <job-id>"
        return 1
    fi

    watch_job $1 ER
}

watch_job_out() {
    if [[ -z "${1}" ]]; then
        echo_error "watch_job_out <job-id>"
        return 1
    fi

    watch_job $1 OU
}

is-run-requirements() {
    if [[ -z $1 ]]; then
        echo_error "is-run-command <requirements> (where \`requirements\` means \`-l\` and \`-q\` args)"
        return 1
    fi

    qsub_command="qsub -I -p +250 ${1} -- /bin/bash -c \"export HOME=${HOME} && cd ~ && /bin/bash\""

    read -p "$(echo "${qsub_command}... proceed? (y/n):" | awk '{$1=$1};1')" -n 1 -r
    echo
    if [[ $REPLY =~ ^y|Y$ ]]; then
        eval ${qsub_command}
    fi
}

is-run() {
    cpus=$([[ $1 =~ ^[0-9]+$ ]]   && echo $1        || echo "")
    rams=$([[ $2 =~ ^[0-9]+$ ]]   && echo "$2gb"    || echo "")
    scrt=$([[ $3 =~ ^[0-9]+$ ]]   && echo "$3gb"    || echo "")
    gpus=$([[ $4 =~ ^[0-9]+$ ]]   && echo "$4"      || echo "")
    other=$([[ ! -z $5 ]]         && echo ":$5"     || echo "")
    queue=$([[ $gpus -eq 0 ]]     && echo "default@meta-pbs.metacentrum.cz" || echo "gpu@meta-pbs.metacentrum.cz")

    if [[ -z $cpus ]] || [[ -z $rams ]] || [[ -z $scrt ]] || [[ -z $gpus ]]; then
        echo_error "is-run <cpus> <rams-gb> <scrt-gb> <gpus> [cluster|city]"
        return 1
    fi

    requirements="-l walltime=10:0:0 -q ${queue} -l select=1:ncpus=${cpus}:ngpus=${gpus}:mem=${rams}:scratch_ssd=${scrt}${other}"
    is-run-requirements "${requirements}"
}

# Create aliases for favourite interactive sesstion configurations
if [[ ! -z $FAVOURITE_IS_CONFIGS ]]; then
    echo_info -e "\nCreating iteractive session aliases..."

    for ((i=0; i<${#FAVOURITE_IS_CONFIGS[@]}; i++)); do
        alias_name="is-$(echo "${FAVOURITE_IS_CONFIGS[$i]}" | tr -s ' ' | tr ' ' '-' | tr '=' '-' | tr ':' '-')"
        alias_body="is-run ${FAVOURITE_IS_CONFIGS[$i]}"

        echo_verbose -n "creating ${alias_name}... "
        alias ${alias_name}="${alias_body}"

        if command -v ${alias_name} &> /dev/null; then
            echo_verbose -e "\033[0;32mok\033[0m"
        else
            echo_verbose -e "\033[0;31mnok!\033[0m"
        fi
    done
fi
