# shellcheck shell=bash
# metaenv: sourced by ~/.bashrc (see install.sh). Shells without a terminal (scp, rsync, `ssh <frontend> is-run …`)
# read it too, so it must never print anything. A PBS job starts in the node's own home, without it: a job script that
# wants it sources this file by its full path.

METAENV_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# bin/ runs anywhere; bin/metacentrum/ (PBS, Singularity) only on MetaCentrum, recognized by a home on /storage
metaenv_path_add() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) export PATH="$1:$PATH" ;;
    esac
}
metaenv_path_add "$METAENV_DIR/bin"
if [[ $HOME == /storage/* ]]; then
    metaenv_path_add "$METAENV_DIR/bin/metacentrum"
fi
unset -f metaenv_path_add

# Tab completion of job ids and images, only for a terminal
if [[ $- == *i* ]]; then
    source "$METAENV_DIR/completion.bash"
fi

# Temporary files into the job's scratch: /tmp of a node has a small limit, and some libraries (and Singularity, when it
# builds or pulls an image) write large intermediate results there.
tmp-to-scratch() {
    if [[ -z ${SCRATCHDIR:-} ]]; then
        echo "tmp-to-scratch: SCRATCHDIR is not set (not in a job with a scratch)" >&2
        return 1
    fi
    export TMPDIR=$SCRATCHDIR/tmp
    export SINGULARITY_TMPDIR=$SCRATCHDIR/singularity_tmp
    export SINGULARITY_CACHEDIR=$SCRATCHDIR/singularity_cache
    mkdir -p "$TMPDIR" "$SINGULARITY_TMPDIR" "$SINGULARITY_CACHEDIR"
}

# done by itself in a job (an is-run session), not for the general /scratch/$USER outside a job
if [[ -n ${SCRATCHDIR:-} && $SCRATCHDIR != "/scratch/$USER" && -d $SCRATCHDIR && -w $SCRATCHDIR ]]; then
    tmp-to-scratch
fi
