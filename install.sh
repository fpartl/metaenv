#!/bin/bash
# Put metaenv into ~/.bashrc of this machine's home (on MetaCentrum: the home of the frontend), or into the given file:
#
#   ./install.sh                    # ~/.bashrc
#   ./install.sh <path>/.bashrc
#
# The same on MetaCentrum and on your machine: shell/metaenv.sh itself puts bin/metacentrum/ on PATH only on
# MetaCentrum.
# Only this one home: `job session` connects to a node with this HOME, whichever storage the node's own home is on.
# The block goes to the top of the file, before any "interactive shells only" part, so the tools are on PATH also
# for `ssh <frontend> job session …`. Running it again replaces the block, the previous file is kept as `*.metaenv.bak`.
# A login shell reads ~/.bash_profile (or ~/.bash_login, ~/.profile) instead: one sourcing ~/.bashrc is made when
# there is none.

set -euo pipefail

if (( $# > 1 )); then
    echo "usage: install.sh [bashrc]" >&2
    exit 2
fi
file=${1:-$HOME/.bashrc}
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# a block without its end line would make the sed below delete the rest of the file
if [[ -f $file ]]; then
    starts=$(grep -c '^# >>> metaenv >>>$' "$file" || true)
    ends=$(grep -c '^# <<< metaenv <<<$' "$file" || true)
    old=$(grep -c '^#\( #\)\? metaenv stuff' "$file" || true)   # the old block starts and ends with this line
    if (( starts != ends || old % 2 )); then
        echo "install.sh: a metaenv block in $file lacks its start or end line, fix it by hand first" >&2
        exit 1
    fi
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
{
    echo "# >>> metaenv >>>"
    printf 'source %q\n' "$dir/shell/metaenv.sh"
    echo "# <<< metaenv <<<"
    if [[ -f $file ]]; then
        # drop this block and the block of the old metaenv (`# metaenv stuff`)
        sed -e '/^# >>> metaenv >>>$/,/^# <<< metaenv <<<$/d' \
            -e '/^#\( #\)\? metaenv stuff/,/^#\( #\)\? metaenv stuff/d' "$file"
    fi
} > "$tmp"

# written into the file, not moved over it: a symlink (dotfiles in a repository) stays and its target gets the block
if [[ -f $file ]]; then
    cp -p "$file" "$file.metaenv.bak"
fi
cat "$tmp" > "$file"
echo "updated $file"

# A login shell (ssh to the frontend, job shell on a node) reads the first of these files that exists, not ~/.bashrc
# (man bash, INVOCATION); the usual one sources ~/.bashrc. Without any of them, one that does; one that does not
# source it is up to you.
home=$(dirname "$file")
for profile in "$home/.bash_profile" "$home/.bash_login" "$home/.profile" ""; do
    if [[ -z $profile || -e $profile ]]; then
        break
    fi
done
if [[ -z $profile ]]; then
    cat > "$home/.bash_profile" <<'PROFILE'
# login shells (ssh, job shell of metaenv) read this file, not ~/.bashrc
if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi
PROFILE
    echo "created $home/.bash_profile, it sources ~/.bashrc"
elif ! grep -q '\.bashrc' "$profile"; then
    {
        echo "warning: $profile does not seem to source ~/.bashrc, so login shells (ssh, job shell) miss metaenv;"
        echo "add to it: if [[ -f ~/.bashrc ]]; then source ~/.bashrc; fi"
    } >&2
fi
