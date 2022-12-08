OVERRIDE_KRB_FILE="FILE:/tmp/krb5cc_$(id -u)"
OVERRIDE_HOME=""

MODULE_PYTHON_ENABLE=1

MODULE_CONDA_ENABLE=1
BASE_CONDA_ENV_ENABLE=1
BASE_CONDA_ENV_NAME="fpartl-base"
BASE_CONDA_ENV_PYTHON="3.10"

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
# Set Kerberos ticket (because of VS Code remote extension)
if [[ ! -z $OVERRIDE_KRB_FILE ]]; then
    echo "Setting KRB5CCNAME=${OVERRIDE_KRB_FILE}!"
    export KRB5CCNAME=$OVERRIDE_KRB_FILE
fi

if [[ ! -z $OVERRIDE_HOME ]]; then
    echo "Setting HOME=${OVERRIDE_HOME}"
    export HOME=$OVERRIDE_HOME
fi

# Activate Python module
if [[ $MODULE_PYTHON_ENABLE -eq 1 ]]; then
    module add python
fi

# Use user based Conda environment
if [[ $MODULE_CONDA_ENABLE -eq 1 ]]; then
    module add conda-modules

    if [[ $BASE_CONDA_ENV_ENABLE -eq 1 ]]; then
        base_conda_env_exitsts=$(conda env list -q | grep $BASE_CONDA_ENV_NAME | wc -l)
        if [[ $base_conda_env_exitsts -ne 1 ]]; then
            echo "Conda env ${BASE_CONDA_ENV_NAME} does not exists... creating now!"

            conda create --name $BASE_CONDA_ENV_NAME --no-default-packages python=$BASE_CONDA_ENV_PYTHON
            conda activate $BASE_CONDA_ENV_NAME

            # Install useful packages
            pip install git+https://github.com/fpartl/metarunner.git
        else
            conda activate $BASE_CONDA_ENV_NAME
        fi
    fi
fi

# Enable custom Docker support
docker-to-sif() {
    if [[ ! -f $1 ]]; then
        echo "docker-to-sif <docker-image-file>"
        return 1
    fi

    singularity_file="${1}.sif"
    singularity build "${singularity_file}" "docker-archive://${1}"

    echo "Run with: singularity shell $(realpath $singularity_file)"
}