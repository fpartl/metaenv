# metaenv

Automatic module initialization, easy export environment variables

## Instalation
Connect to your favourite [MetaVO frontend machine](https://wiki.metacentrum.cz/wiki/Frontend) via SSH. In the next example, the front node `nympha.zcu.cz` is used.
```console
your_name@nympha~$ git clone https://github.com/fpartl/metaenv.git .metaenv_repo
Cloning into '.metaenv_repo'...
...
your_name@nympha~$ cd .metaenv_repo
your_name@nympha~/.metaenv_repo$ chmod +x install.sh # may not be necessary
your_name@nympha~$ git checkout latest
Branch 'latest' set up to track remote branch 'latest' from 'origin'.
...
your_name@nympha~$ git status # should say "nothing to commit, working tree clean"
...
nothing to commit, working tree clean
your_name@nympha~$ ./install.sh
In which home directory do you want to install scripts? (/storage/plzen1/home/your_name):

Installing user configuration file...

Creating symlinks...
creating /storage/plzen1/home/fpartl/.bash_functions...
creating /storage/plzen1/home/fpartl/.bash_login...
creating /storage/plzen1/home/fpartl/.bash_modules...
creating /storage/plzen1/home/fpartl/.bash_profile...
creating /storage/plzen1/home/fpartl/.bashrc...

Installation completed! Have a nice day!
your_name@nympha~$ 
```

The installation script does the following:
1. Asks for your home directory where the `.bash*` scripts will be installed (as symlinks to the `metaenv` repository clone). The default home directory is the current value of the `HOME` environment variable.
2. Furthermore, it creates a `.metaenv_user_conf` file, which is intended for you to edit and customize your metavo environment (not a symlink).
3. If any of the files already exist, the installation script will overwrite them with your consent (consider backing up your old scripts).

## Update
To update simply navigate to your `metaenv` repository clone and pull changes from `latest` branch. Reinstallation is required only when the `.metaenv_user_conf` file structure is changed.
```console
your_name@nympha~$ cd .metaenv_repo
your_name@nympha~/.metaenv_repo$ git fetch
your_name@nympha~/.metaenv_repo$ git checkout latest
your_name@nympha~/.metaenv_repo$ git reset --hard FETCH_HEAD
your_name@nympha~/.metaenv_repo$ ./install.sh # may not be necessary
...
```

## Setting things up
See comments in your freshly installed `.metaenv_user_conf` file.

Enjoy! :sunglasses:
