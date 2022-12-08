#!/bin/bash

# Bash pro inicializaci někdy používá ~/.bashrc, někdy ~/.bash_profile a někdy ~/.bash_login.
# Nasourcujeme sem ~/.bashrc, abychom zajistili, že soubory ~/.bashrc a ~/.bash_profile jsou ekvivelentní,
# tj. že Bash bude inicializovaný vždy stejně, ať už jde o login shell, interaktivní shell, atd.
# (více info viz "man bash")
if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi