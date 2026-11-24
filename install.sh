#!/bin/bash
# Put metaenv into ~/.bashrc of this machine's home (on MetaCentrum: the home of the frontend), or into the given file:
#
#   ./install.sh                    # ~/.bashrc
#   ./install.sh <path>/.bashrc
#
# The same on MetaCentrum and on your machine: metaenv.sh itself puts metacentrum/ on PATH only on MetaCentrum.
# Only this one home: `is-run` connects to a node with this HOME, whichever storage the node's own home is on.
# The block goes to the top of the file, before any "interactive shells only" part, so the tools are on PATH also
# for `ssh <frontend> is-run …`. Running it again replaces the block, the previous file is kept as `*.metaenv.bak`.

set -euo pipefail

if (( $# > 1 )); then
    echo "usage: install.sh [bashrc]" >&2
    exit 2
fi
file=${1:-$HOME/.bashrc}
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

tmp=$(mktemp "$file.XXXXXX")
{
    echo "# >>> metaenv >>>"
    printf 'source %q\n' "$dir/metaenv.sh"
    echo "# <<< metaenv <<<"
    if [[ -f $file ]]; then
        # drop this block and the block of the old metaenv (`# metaenv stuff`)
        sed -e '/^# >>> metaenv >>>$/,/^# <<< metaenv <<<$/d' \
            -e '/^#\( #\)\? metaenv stuff/,/^#\( #\)\? metaenv stuff/d' "$file"
    fi
} > "$tmp"

if [[ -f $file ]]; then
    chmod --reference="$file" "$tmp"
    cp -p "$file" "$file.metaenv.bak"
else
    chmod 644 "$tmp"
fi
mv "$tmp" "$file"
echo "updated $file"
