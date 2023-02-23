### User configurations ######################################################################
# Add your favourie software to the PATH variable
export PATH="${HOME}/vscode-server:${PATH}"
export PATH="${HOME}/tools/julia-1.8.5/bin:${PATH}"

# Rewrite environment variables
ENVIRONMENT_VARS=(
    KRB5CCNAME="FILE:/tmp/krb5cc_$(id -u)"
)

# Automatically initialize frequently used modules
# Warning! List of available modules seems to vary by Metacenter's node...
INITIALIZED_MODULES=(
    python
    conda-modules
    # julia-1.5.3-gcc
)

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
# Rewrite environment variables
if [[ ! -z ${ENVIRONMENT_VARS} ]]; then
    echo "Exporting environment variables..."

    for var_line in ${ENVIRONMENT_VARS[@]}; do
        IFS='=' read -ra var_line_arr <<< ${var_line}
        var_name=${var_line_arr[0]}
        var_value=${var_line_arr[1]}

        echo -n "exporting ${var_name}=${var_value}... "
        export_command_output=$((export ${var_name}=${var_value}) 2>&1)

        if [[ -z ${export_command_output} ]]; then
            echo -e "\033[0;32mok\033[0m"
        else
            echo -e "\033[0;31mnok!\033[0m (error: ${export_command_output})"
            echo -e ""
        fi
    done
fi

# Enable `module` command
. /software/modules/init

# Initialize modules from INITIALIZED_MODULES array and much more!
if [[ -f ~/.bash_modules ]]; then
    source ~/.bash_modules
fi

# Some additional useful functions
if [[ -f ~/.bash_functions ]]; then
    source ~/.bash_functions
fi
