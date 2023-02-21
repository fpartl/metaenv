OVERRIDE_KRB_FILE="FILE:/tmp/krb5cc_$(id -u)"
OVERRIDE_HOME="" # not really tested feature...

MODULE_PYTHON_ENABLE=1
MODULE_CONDA_ENABLE=1
MODULE_JULIA_ENABLE=1

### Metacentrum recommendation ###############################################################
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

### My initialization scripts ################################################################
. /software/modules/init

if [[ -f ~/.bash_modules ]]; then
    source ~/.bash_modules
fi

if [[ -f ~/.bash_functions ]]; then
    source ~/.bash_functions
fi

# Set Kerberos ticket (because of VS Code remote extension)
if [[ ! -z $OVERRIDE_KRB_FILE ]]; then
    echo "exporting KRB5CCNAME=${OVERRIDE_KRB_FILE}"
    export KRB5CCNAME=$OVERRIDE_KRB_FILE
fi

if [[ ! -z $OVERRIDE_HOME ]]; then
    echo "exporting HOME=${OVERRIDE_HOME}"
    export HOME=$OVERRIDE_HOME
fi

echo

# Activate Python module
if [[ $MODULE_PYTHON_ENABLE -eq 1 ]]; then
    echo "Module python added"
    enable_python
fi

# Use user based Conda environment
if [[ $MODULE_CONDA_ENABLE -eq 1 ]]; then
    echo "Module conda-modules added"
    enable_conda
fi

# Activate Julia module
if [[ $MODULE_JULIA_ENABLE -eq 1 ]]; then
    echo "Module julia added"
    enable_julia
fi

export PATH="/storage/plzen1/home/$(whoami)/vscode-server:${PATH}"
