#!/bin/bash

# TMPDIR to SCRATCHDIR mappings
tmp-to-scratch() {
    tmp_dir="${SCRATCHDIR}/tmp"
    mkdir -p "${tmp_dir}"
    export TMPDIR="${tmp_dir}"
}
sin-tmp-to-scratch() {
    tmp_dir="${SCRATCHDIR}/singularity_tmp"
    mkdir -p "${tmp_dir}"
    export SINGULARITY_TMPDIR="${tmp_dir}"
}
sin-cache-to-scratch() {
    tmp_dir="${SCRATCHDIR}/singularity_cache"
    mkdir -p "${tmp_dir}"
    export SINGULARITY_CACHEDIR="${tmp_dir}"
}

# Run VS Code server
if command -v code &> /dev/null; then
    alias vscode-server="$(which code) tunnel --log trace --verbose"
fi

