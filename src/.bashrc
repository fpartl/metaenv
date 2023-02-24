### Metacenter's recommendation ###############################################################
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
# Load user defined configuration arrays
if [[ -f ~/.metaenv_user_conf ]]; then
    source ~/.metaenv_user_conf
fi

# Rewrite environment variables
if [[ ! -z ${ENVIRONMENT_VARS} ]]; then
    echo "Exporting environment variables..."

    for ((i=0; i<${#ENVIRONMENT_VARS[@]}; i++)); do
        IFS='=' read -ra var_line_arr <<< "${ENVIRONMENT_VARS[$i]}"
        var_name="${var_line_arr[0]}"
        var_value="${var_line_arr[1]}"

        echo -n "exporting ${var_name}=\"${var_value}\"... "
        export ${var_name}="${var_value}"

        if [[ ${!var_name} == ${var_value} ]]; then
            echo -e "\033[0;32mok\033[0m"
        else
            echo -e "\033[0;31mnok!\033[0m"
        fi
    done
fi

# Add your software to PATH
if [[ ! -z ${EXTRA_PATH_DIRS} ]]; then
    echo
    echo "Adding items to PATH variable..."

    for ((i=0; i<${#EXTRA_PATH_DIRS[@]}; i++)); do
        echo -n "adding \"${EXTRA_PATH_DIRS[$i]}\"... "
        export PATH="${EXTRA_PATH_DIRS[$i]}:${PATH}"

        if [[ "${PATH}" == *"${path}"* ]]; then
            echo -e "\033[0;32mok\033[0m"
        else
            echo -e "\033[0;31mnok!\033[0m"
        fi
    done
fi

# Enable `module` command
. /software/modules/init

# Initialize modules from INITIALIZED_MODULES array and much more!
if [[ -f ~/.bash_modules ]]; then
    source ~/.bash_modules
fi

# Initialize of interactive session aliases and much more!
if [[ -f ~/.bash_functions ]]; then
    source ~/.bash_functions
fi
