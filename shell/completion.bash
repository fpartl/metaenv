# shellcheck shell=bash
# Tab completion of the metaenv tools, sourced by metaenv.sh in interactive shells: the commands of `job` and `sif`,
# then job ids (from qstat, newest first) and files of the right type. With fzf loaded (`eval "$(fzf --bash)"`),
# `job info **<Tab>` picks the job in fzf, with its state, name and queue; only the id goes to the command line.

# Completes the current word with the given words.
_metaenv_complete_words() {
    mapfile -t COMPREPLY < <(compgen -W "$1" -- "${COMP_WORDS[COMP_CWORD]}")
}

# Completes the current word with files matching the glob (e.g. '*.sif') and folders.
_metaenv_complete_file() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    compopt -o filenames
    mapfile -t COMPREPLY < <(compgen -f -X "!$1" -- "$cur"; compgen -d -- "$cur")
}

# sif <command>: anywhere (bin/)
_metaenv_sif() {
    if (( COMP_CWORD == 1 )); then
        _metaenv_complete_words "tag build shell from-docker"
        return
    fi
    case ${COMP_WORDS[1]} in
        tag | build)
            compopt -o filenames
            mapfile -t COMPREPLY < <(compgen -d -- "${COMP_WORDS[COMP_CWORD]}")
            ;;
        shell)
            # the image, then a command in it (default completion)
            if (( COMP_CWORD == 2 )); then
                _metaenv_complete_file '*.sif'
            fi
            ;;
        from-docker)
            if (( COMP_CWORD == 2 )); then
                _metaenv_complete_file '*.tar'
            elif (( COMP_CWORD == 3 )); then
                _metaenv_complete_file '*.sif'
            fi
            ;;
    esac
}
complete -F _metaenv_sif -o default sif

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

# job <command>: ids of unfinished jobs for shell, extend and kill, also of finished ones for info and log
_metaenv_job() {
    if (( COMP_CWORD == 1 )); then
        _metaenv_complete_words "session list info shell extend kill log"
        return
    fi
    case ${COMP_WORDS[1]} in
        list) _metaenv_complete_words "-x" ;;
        info)
            if [[ ${COMP_WORDS[COMP_CWORD]} == -* ]]; then
                _metaenv_complete_words "-c -e -v"
            else
                _metaenv_complete_job -x
            fi
            ;;
        shell)
            if (( COMP_CWORD == 2 )); then
                _metaenv_complete_job
            fi
            ;;
        extend)
            # job ids start with a digit, so a word starting with a letter can only be `info`
            if (( COMP_CWORD == 2 )) && [[ ${COMP_WORDS[2]} == [a-z]* ]]; then
                _metaenv_complete_words "info"
            elif (( COMP_CWORD == 2 )); then
                _metaenv_complete_job
            fi
            ;;
        kill) _metaenv_complete_job ;;
        log)
            if (( COMP_CWORD == 2 )); then
                _metaenv_complete_words "out err"
            elif (( COMP_CWORD == 3 )); then
                _metaenv_complete_job -x
            fi
            ;;
    esac
}
complete -F _metaenv_job job

# wjo <id>, wje <id>: also a finished job
_metaenv_wjo() {
    if (( COMP_CWORD == 1 )); then
        _metaenv_complete_job -x
    fi
}
complete -F _metaenv_wjo wjo wje

# PBS's own commands: qdel <id>..., qextend <id> <hh:mm:ss> | info
_metaenv_qdel() {
    _metaenv_complete_job
}
complete -F _metaenv_qdel qdel

_metaenv_qextend() {
    if (( COMP_CWORD == 1 )) && [[ ${COMP_WORDS[1]} == [a-z]* ]]; then
        _metaenv_complete_words "info"
    elif (( COMP_CWORD == 1 )); then
        _metaenv_complete_job
    fi
}
complete -F _metaenv_qextend qextend
