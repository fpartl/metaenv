# shellcheck shell=bash
# Tab completion of the metaenv tools, sourced by metaenv.sh in interactive shells: the commands of `job` and `sif`,
# then job ids (from qstat, newest first) and files of the right type. With fzf loaded (`eval "$(fzf --bash)"`),
# `job info **<Tab>` picks the job in fzf, with its state, name and queue; only the id goes to the command line.

# Completes the current word with the given words.
_metaenv_complete_words() {
    mapfile -t COMPREPLY < <(compgen -W "$1" -- "${COMP_WORDS[COMP_CWORD]}")
}

# Drops from COMPREPLY what is already on the command line from the word with the given index (2 after
# `<command> <subcommand>`) on; a job id also by its short form, as job list shows it.
_metaenv_drop_given() {
    local word given=" " kept=()
    for word in "${COMP_WORDS[@]:$1:COMP_CWORD-$1}"; do
        given+="${word%%.*} "
    done
    for word in "${COMPREPLY[@]}"; do
        if [[ $given != *" ${word%%.*} "* ]]; then
            kept+=("$word")
        fi
    done
    COMPREPLY=("${kept[@]}")
}

# Completes the current word with files matching the glob (e.g. '*.sif') and folders.
_metaenv_complete_file() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    compopt -o filenames
    mapfile -t COMPREPLY < <(compgen -f -X "!$1" -- "$cur"; compgen -d -- "$cur")
}

# Completes the current word with folders.
_metaenv_complete_dir() {
    compopt -o filenames
    mapfile -t COMPREPLY < <(compgen -d -- "${COMP_WORDS[COMP_CWORD]}")
}

# sif <command>: anywhere (bin/). Each command gets only the words it takes, nothing after them.
_metaenv_sif() {
    if (( COMP_CWORD == 1 )); then
        _metaenv_complete_words "tag build shell from-docker"
        return
    fi
    case ${COMP_WORDS[1]} in
        tag)
            if (( COMP_CWORD == 2 )); then
                _metaenv_complete_dir
            fi
            ;;
        build)
            # [-n NAME] <images>: no completion of the name; the folder once
            local word previous=${COMP_WORDS[COMP_CWORD-1]} folder_given=0 after_n=0
            for word in "${COMP_WORDS[@]:2:COMP_CWORD-2}"; do
                if (( after_n )); then
                    after_n=0
                elif [[ $word == -n ]]; then
                    after_n=1
                else
                    folder_given=1
                fi
            done
            if [[ $previous == -n ]]; then
                return
            elif [[ ${COMP_WORDS[COMP_CWORD]} == -* ]]; then
                _metaenv_complete_words "-n"
                _metaenv_drop_given 2
            elif (( ! folder_given )); then
                _metaenv_complete_dir
            fi
            ;;
        shell)
            # the image, then a command in it and its arguments (bash's default completion)
            if (( COMP_CWORD == 2 )); then
                _metaenv_complete_file '*.sif'
            else
                compopt -o default
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
complete -F _metaenv_sif sif

[[ $HOME == /storage/* ]] || return 0

# My jobs, newest first: "<id> <state> <name> <queue>"; with -x also the finished ones (qstat keeps them for a while).
_metaenv_jobs() {
    qstat -w -u "$USER" "$@" 2>/dev/null | awk '$1 ~ /^[0-9]/ { print $1, $10, $4, $3 }' | tac
}

# Whether the current word asks for fzf: it ends with the trigger (**) and fzf's completion is loaded.
_metaenv_fzf_asked() {
    [[ ${COMP_WORDS[COMP_CWORD]} == *"${FZF_COMPLETION_TRIGGER-**}" ]] && declare -F _fzf_complete >/dev/null
}

# Completes the current word with the jobs `_metaenv_jobs "$@"` lists: by fzf after the trigger (**), else by plain
# bash completion of the ids.
_metaenv_complete_job() {
    if _metaenv_fzf_asked; then
        _metaenv_fzf_job "$@"
        return
    fi
    mapfile -t COMPREPLY < <(compgen -W "$(_metaenv_jobs "$@" | cut -d' ' -f1)" -- "${COMP_WORDS[COMP_CWORD]}")
}

# fzf shows the whole lines, _metaenv_fzf_job_post (found by fzf by the name of the caller) keeps only the id
_metaenv_fzf_job() {
    _fzf_complete --no-multi --header="id state name queue" -- "${COMP_WORDS[0]}" < <(_metaenv_jobs "$@" | column -t)
}
_metaenv_fzf_job_post() {
    cut -d' ' -f1
}

# job <command>: each command gets only the words it takes, nothing after them. Ids of the jobs that have not
# finished, as `job list`; also of finished ones for log, whose output is mostly read then, and in fzf for info, where
# the state shows and finished ones can be filtered out.
_metaenv_job() {
    if (( COMP_CWORD == 1 )); then
        _metaenv_complete_words "session list info shell attach extend kill log"
        return
    fi
    case ${COMP_WORDS[1]} in
        session)
            # its options (job session -h), each once but -l; their values are numbers or the user's own, not completed
            if [[ ${COMP_WORDS[COMP_CWORD-1]} == -[cglmqsw] ]]; then
                return
            fi
            if [[ ${COMP_WORDS[COMP_CWORD]} == -* ]]; then
                _metaenv_complete_words "-c -g -m -s -w -q -l -h"
                local options=("${COMPREPLY[@]}")
                _metaenv_drop_given 2
                if [[ " ${options[*]} " == *" -l "* && " ${COMPREPLY[*]} " != *" -l "* ]]; then
                    COMPREPLY+=(-l)
                fi
            fi
            ;;
        list)
            if (( COMP_CWORD == 2 )); then
                _metaenv_complete_words "-x"
            fi
            ;;
        info)
            # one id: once it is there, only the options not given yet
            local word id_given=0
            for word in "${COMP_WORDS[@]:2:COMP_CWORD-2}"; do
                if [[ $word != -* ]]; then
                    id_given=1
                fi
            done
            if [[ ${COMP_WORDS[COMP_CWORD]} == -* ]] || (( id_given )); then
                _metaenv_complete_words "-c -e -v"
                _metaenv_drop_given 2
            elif _metaenv_fzf_asked; then
                _metaenv_complete_job -x
            else
                _metaenv_complete_job
            fi
            ;;
        shell | attach)
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
        kill)
            # more ids, each once
            _metaenv_complete_job
            _metaenv_drop_given 2
            ;;
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
    _metaenv_drop_given 1
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
