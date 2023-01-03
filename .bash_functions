#!/bin/bash

# Enable SCRATCH->TMP mapping
alias tmp-to-scratch='export TMPDIR=$SCRATCHDIR'

docker-to-sif() {
    docker_image=$([[ -f $1 ]] && echo $1 || echo "")
    singul_image=$([[ -z $2 ]] && echo "${docker_image}.sif" || echo $2 )

    # Check if input file exists
    if [[ -z $docker_image ]]; then
        echo "docker-to-sif <docker-image-file> [singularity-output-sif]"
        return 1
    fi

    # Set $SCRATCHDIR to $TMPDIR if scratchdir is available
    if [[ $SCRATCHDIR != "/scratch/${USER}" ]]; then
        tmp-to-scratch
    fi

    # Build singularity image
    singularity build "${singul_image}" "docker-archive://${docker_image}"

    echo "Run with: singularity shell $(realpath $singul_image)"
}

is-run() {
    cpus=$([[ $1 =~ ^[0-9]+$ ]]   && echo $1          || echo "")
    rams=$([[ $2 =~ ^[0-9]+$ ]]   && echo "$2gb"      || echo "")
    scrt=$([[ $3 =~ ^[0-9]+$ ]]   && echo "$3gb"      || echo "")
    city=$([[ ! -z $4 ]]          && echo ":$4=True"  || echo "")

    if [[ -z $cpus ]] || [[ -z $rams ]] || [[ -z $scrt ]]; then
        echo $cpus $rams $scrt
        echo "is-run <cpus> <rams-gb> <scrt-gb> [city]"
        return 1
    fi

    qsub_command="
        qsub -I \
            -p +250 \
            -l walltime=3:0:0 -q default@meta-pbs.metacentrum.cz \
            -l select=1:ncpus=${cpus}:mem=${rams}:scratch_local=${scrt}${city}
    "

    read -p "$(echo "${qsub_command}... proced? (y/n):" | xargs) " -n 1 -r
    echo
    if [[ $REPLY =~ ^y|Y$ ]]; then
        eval ${qsub_command}
    fi
}

is-1-1-1-plzen() {
    is-run 1 1 1 plzen
}

is-4-16-20-plzen() {
    is-run 4 16 20 plzen
}