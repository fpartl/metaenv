#!/bin/bash

### TMPDIR MAPPING #############################################################
# map `tmp` to $SCRATCHDIR if available
if [[ ! -z $MAP_TMP_TO_SCRATCH && "${SCRATCHDIR}" != "/scratch/${USER}" ]]; then
    echo_info "Mapping TMPDIR to SCRATCHDIR..."

    tmp-to-scratch
    echo_info "exporting TMPDIR=\"${TMPDIR}\""

    sin-tmp-to-scratch
    echo_info "exporting SINGULARITY_TMPDIR=\"${TMPDIR}\""

    sin-cache-to-scratch
    echo_info "exporting SINGULARITY_CACHEDIR=\"${TMPDIR}\""
fi

### JOB WATCHING ###############################################################

watch_job() {
    # Check input arguments
    if [[ -z "${1}" ]] || [[ ! "${2}" =~ ^(ER|OU)$ ]]; then
        echo_error "watch_job <job-id> <ER|OU>"
        return 1
    fi

    # Get job status using `qstat` command (including nonrunning jobs)
    job_id=$(echo "${1}" | cut -f1 -d".")
    job_queue=$(qstat -xf $job_id | sed -n -e 's/^ *queue = [^@]*//p')
    qstat_output=$(qstat -xf -F dsv ${job_id}${job_queue} 2>&1)

    # Check if job exists
    job_exists=$(echo "${qstat_output}" | grep "qstat: Unknown Job Id" | wc -l)
    if [[ $job_exists -ne 0 ]]; then
        echo_error "qstat: Unknown job id ${job_id}"
        echo_info "You should check your jobs at: https://metavo.metacentrum.cz/pbsmon2/user/${USER}"
        return 2
    fi

    # Get job information
    job_id=$(echo "${qstat_output}" | perl -n -e'/Job Id: (.*?)\|/gm && print $1')
    job_state=$(echo "${qstat_output}" | perl -n -e'/job_state=(.*?)\|/gm && print $1')
    job_exit_code=$(echo "${qstat_output}" | perl -n -e'/Exit_status=(.*?)\|/gm && print $1')

    # Print some basic job information
    echo_info "Info: job_id=${job_id}"
    echo_info -e "Info: job_state=\033[1;$([[ $job_state == "R" ]] && echo "32" || echo "34")m${job_state}\033[0m"

    ### Job is currently runnning
    if [[ $job_state == "R" ]]; then
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
        # Print exit code if available
        if [[ ! -z $job_exit_code ]]; then
            code_color=$([[ $job_exit_code -eq 0 ]] && echo "32" || echo "34")
            echo_info -e "Info: Exit_status=\033[1;${code_color}m${job_exit_code}\033[0m"
        fi

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
        echo && echo -e "\033[1;34mLess of ${out_file}:\033[0m"
        less "${out_file}"
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

# Some conveninet aliases
alias wje="watch_job_err"
alias wjo="watch_job_out"

### INTERACTIVE SESSIONS #######################################################

is-run-requirements() {
    if [[ -z $1 ]]; then
        echo_error "is-run-command <qsub-params>"
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
    cpus=$([[ $1 =~ ^[0-9]+$ ]]         && echo $1                                  || echo "")
    rams=$([[ $2 =~ ^[0-9]+$ ]]         && echo "$2gb"                              || echo "")
    scrt=$([[ $3 =~ ^[0-9]+$ ]]         && echo "$3gb"                              || echo "")
    gpus=$([[ $4 =~ ^[0-9]+$ ]]         && echo "$4"                                || echo "")
    other=$([[ ! -z $5 ]]               && echo ":$5"                               || echo "")
    queue=$([[ $gpus -eq 0 ]]           && echo "default@pbs-m1.metacentrum.cz"   || echo "gpu@pbs-m1.metacentrum.cz")
    mail=$([[ ! -z $IS_MAIL ]]          && echo "${IS_MAIL}"                        || echo "n")
    walltime=$([[ ! -z $IS_WALLTIME ]]  && echo "${IS_WALLTIME}"                    || echo "12")

    if [[ -z $cpus ]] || [[ -z $rams ]] || [[ -z $scrt ]] || [[ -z $gpus ]] || [[ ! $mail =~ ^(abe|be|ae|ab|n|e|b|a)$ ]] || [[ -z $walltime ]]; then
        echo_error -e "[IS_MAIL=a|b|e] [IS_WALLTIME=hh (default 12)] is-run <cpus> <rams-gb> <scrt-gb> <gpus> [cluster|city] \nemail notification options: \033[1;34mhttps://wiki.metacentrum.cz/wiki/About_scheduling_system#How_to_setup_email_notification_about_job_state\033[0m"
        return 1
    fi

    requirements="-m ${mail} -l walltime=${walltime}:00:00 -q ${queue} -l select=1:ncpus=${cpus}:ngpus=${gpus}:mem=${rams}:scratch_ssd=${scrt}${other}"
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
