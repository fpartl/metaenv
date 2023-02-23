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
    gpus=$([[ $4 =~ ^[0-9]+$ ]]   && echo "$4"        || echo "")
    city=$([[ ! -z $5 ]]          && echo ":$5=True"  || echo "")
    queue=$([[ $gpus -eq 0 ]]     && echo "default@meta-pbs.metacentrum.cz" || echo "gpu@meta-pbs.metacentrum.cz")

    if [[ -z $cpus ]] || [[ -z $rams ]] || [[ -z $scrt ]] || [[ -z $gpus ]]; then
        echo $cpus $rams $scrt
        echo "is-run <cpus> <rams-gb> <scrt-gb> <gpus> [city]"
        return 1
    fi

    qsub_command="qsub -I \
                    -p +250 \
                    -l walltime=6:0:0 -q ${queue} \
                    -l select=1:ncpus=${cpus}:ngpus=${gpus}:mem=${rams}:scratch_ssd=${scrt}${city} \
                    -- /bin/bash -c \"export TMPDIR=$SCRATCHDIR && export HOME=${HOME} && cd ~ && /bin/bash\""

    read -p "$(echo "${qsub_command}... proced? (y/n):" | awk '{$1=$1};1')" -n 1 -r
    echo
    if [[ $REPLY =~ ^y|Y$ ]]; then
        eval ${qsub_command}
    fi
}

is-1-8-16-0-plzen() {
    is-run 1 8 16 0 plzen
}

is-2-16-32-0-plzen() {
    is-run 2 16 32 0 plzen
}

is-4-16-32-0-plzen() {
    is-run 4 16 32 0 plzen
}

is-2-32-32-1() {
    is-run 2 32 32 1
}

is-3-32-32-0() {
    is-run 3 32 32 0
}

is-2-32-32-0() {
    is-run 2 32 32 0
}
