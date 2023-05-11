### Metacenter's recommendation ############################################################
# from https://wiki.metacentrum.cz/wiki/U%C5%BEivatel:Mmares/Co_si_d%C3%A1t_do_.bashrc%3F

# Následující řádek vám obarví prompt (např. mmares@metasw8) na zeleno a cestu za ním (např. /software/dirac) na modro
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Bash bude uchovávat posledních 2000 příkazů (zobrazíte je příkazem "history")
export HISTSIZE=2000

# Aliasy pro "ls", aby vypsané názvy souborů byly barevné podle typu (složka, soft link, obyčejný soubor...)
alias ls="ls --color=auto"
alias ll="ls -l --color=auto"

# Příkaz "cat source.c" vypíše obsah souboru, ale neumí zvýraznit syntaxi a proto se takto vypsaný soubor
# špatně čte. Proto jsem vytvořil tento alias - "dog source.c" vypíše obsah souboru, ale zároveň automaticky
# detekuje typ souboru a zvýrazní syntaxi (např. jak na této wiki stránce)
alias dog="pygmentize -g -P bg=dark"

# Funkce umožňující okamžité přepnutí do složky s modulefiles (stačí dát příkaz "cd_modulefiles" a jsme tam!)
cd_modulefiles() {
    cd /afs/.ics.muni.cz/packages/amd64_linux26/modules-2.0/modulefiles
}

# Enable `module` command
if ! command -v module &> /dev/null; then
    . /software/modules/init
fi

### metaenv internal functions ############################################################
# Available verbosity levels
AVAIL_VERBOSITY_LEVELS=(
    quiet=0
    error=1
    warning=2
    info=3
    verbose=4
)

# Load user defined configuration arrays
if [[ -f ~/.metaenv_user_conf ]]; then
    . ~/.metaenv_user_conf
fi

# Generate verbosity levels aliases
if [[ ! -z ${AVAIL_VERBOSITY_LEVELS} ]]; then
    for ((i=0; i<${#AVAIL_VERBOSITY_LEVELS[@]}; i++)); do
        IFS='=' read -ra verbosity_line <<< "${AVAIL_VERBOSITY_LEVELS[$i]}"
        echo_fnc_name="echo_${verbosity_line[0]}"
        verbosity_level="${verbosity_line[1]}"

        eval "${echo_fnc_name}() {
            if [[ ${VERBOSITY_LEVEL} -ge ${verbosity_level} ]]; then
                echo \"\$@\"
            fi
        }"
    done
fi

### Initialization scripts ################################################################
METAENV_SRC_DIR=$(realpath "${HOME}/.bashrc" | xargs dirname)

# Initilialize environment variables and PATH
if [[ -f "${METAENV_SRC_DIR}/.bash_env" ]]; then
    . "${METAENV_SRC_DIR}/.bash_env"
fi

# Initialize of frequently used aliases
if [[ -f "${METAENV_SRC_DIR}/.bash_aliases" ]]; then
    . "${METAENV_SRC_DIR}/.bash_aliases"
fi

# Initialize modules from INITIALIZED_MODULES array and much more!
if [[ -f "${METAENV_SRC_DIR}/.bash_modules" ]]; then
    . "${METAENV_SRC_DIR}/.bash_modules"
fi

# Initialize of interactive session aliases and much more!
if [[ -f "${METAENV_SRC_DIR}/.bash_jobs" ]]; then
    . "${METAENV_SRC_DIR}/.bash_jobs"
fi

# Initialize of container support (Docker + Singularity)
if [[ -f "${METAENV_SRC_DIR}/.bash_containers" ]]; then
    . "${METAENV_SRC_DIR}/.bash_containers"
fi
