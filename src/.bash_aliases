#!/bin/bash

# Enable SCRATCH->TMP mapping
alias tmp-to-scratch='export TMPDIR=$SCRATCHDIR'

# Run VS Code server
if command -v code &> /dev/null; then
    alias vscode-server="code tunnel --log trace --verbose"
fi

