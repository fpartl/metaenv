# shellcheck shell=bash
# Tab completion of the metaenv tools, sourced by metaenv.sh in interactive shells. Tab completes job ids (from qstat,
# newest first) and files of the right type. With fzf loaded (`eval "$(fzf --bash)"`), `wjo **<Tab>` picks the job in
# fzf, with its state, name and queue; only the id goes to the command line.

# bin/: anywhere
complete -d sif-tag
complete -d sif-build

[[ $HOME == /storage/* ]] || return 0

# My jobs, newest first: "<id> <state> <name> <queue>"; with -x also the finished ones (qstat keeps them for a while).
_metaenv_jobs() {
    qstat -w -u "$USER" "$@" 2>/dev/null | awk '$1 ~ /^[0-9]/ { print $1, $10, $4, $3 }' | tac
}

# Completes the current word with the jobs `_metaenv_jobs "$@"` lists: by fzf after the trigger (**), else by plain
# bash completion of the ids.
_metaenv_complete_job() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    if [[ $cur == *"${FZF_COMPLETION_TRIGGER-**}" ]] && declare -F _fzf_complete >/dev/null; then
        _metaenv_fzf_job "$@"
        return
    fi
    mapfile -t COMPREPLY < <(compgen -W "$(_metaenv_jobs "$@" | cut -d' ' -f1)" -- "$cur")
}

# fzf shows the whole lines, _metaenv_fzf_job_post (found by fzf by the name of the caller) keeps only the id
_metaenv_fzf_job() {
    _fzf_complete --no-multi --header="id state name queue" -- "${COMP_WORDS[0]}" < <(_metaenv_jobs "$@" | column -t)
}
_metaenv_fzf_job_post() {
    cut -d' ' -f1
}

# Completes the current word with files matching the glob (e.g. '*.sif') and folders.
_metaenv_complete_file() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    compopt -o filenames
    mapfile -t COMPREPLY < <(compgen -f -X "!$1" -- "$cur"; compgen -d -- "$cur")
}

# job id, also of a finished job: wjo <id>, wje <id>, job-info <id> <attribute>..., job-log <out|err> <id>
_metaenv_wjo() {
    if (( COMP_CWORD == 1 )); then
        _metaenv_complete_job -x
    fi
}
complete -F _metaenv_wjo wjo wje job-info

_metaenv_job_log() {
    if (( COMP_CWORD == 1 )); then
        mapfile -t COMPREPLY < <(compgen -W "out err" -- "${COMP_WORDS[COMP_CWORD]}")
    elif (( COMP_CWORD == 2 )); then
        _metaenv_complete_job -x
    fi
}
complete -F _metaenv_job_log job-log

# a job that has not finished: qdel <id>..., job-shell [id], qextend <id> <hh:mm:ss> | info
_metaenv_qdel() {
    _metaenv_complete_job
}
complete -F _metaenv_qdel qdel job-shell

_metaenv_qextend() {
    # job ids start with a digit, so a word starting with a letter can only be `info`
    if (( COMP_CWORD == 1 )) && [[ ${COMP_WORDS[1]} == [a-z]* ]]; then
        mapfile -t COMPREPLY < <(compgen -W "info" -- "${COMP_WORDS[1]}")
    elif (( COMP_CWORD == 1 )); then
        _metaenv_complete_job
    fi
}
complete -F _metaenv_qextend qextend

# images: sinshell <image.sif> [command...], docker-to-sif <archive.tar> [output.sif]
_metaenv_sinshell() {
    if (( COMP_CWORD == 1 )); then
        _metaenv_complete_file '*.sif'
    fi
}
complete -F _metaenv_sinshell -o default sinshell

_metaenv_docker_to_sif() {
    if (( COMP_CWORD == 1 )); then
        _metaenv_complete_file '*.tar'
    elif (( COMP_CWORD == 2 )); then
        _metaenv_complete_file '*.sif'
    fi
}
complete -F _metaenv_docker_to_sif docker-to-sif
