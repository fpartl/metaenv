# metaenv

Automatic module initialization, easy export environment variables, singularity integration, interactive sessions helper and much more!

## Instalation
Connect to your favourite [MetaVO frontend machine](https://wiki.metacentrum.cz/wiki/Frontend) via SSH. In the next example, the front node `nympha.zcu.cz` is used.
```console
your_name@nympha~$ mkdir tools && cd tools
your_name@nympha~/tools$ git clone https://github.com/fpartl/metaenv.git
Cloning into 'metaenv'...
...
your_name@nympha~$ cd metaenv
your_name@nympha~/tools/metaenv$ chmod +x install.sh # may not be necessary
your_name@nympha~$ ./install.sh
In which home directory do you want to install scripts?: (/storage/praha1/home/fpartl): 

Installing user configuration file...
File /storage/praha1/home/fpartl/.metaenv_user_conf already exists. Are you really sure you want to rewrite it?! (y/n)
...

Creating symlinks...
creating /storage/praha1/home/fpartl/.bash_aliases...
creating /storage/praha1/home/fpartl/.bash_containers...
creating /storage/praha1/home/fpartl/.bash_jobs...
creating /storage/praha1/home/fpartl/.bash_login...
creating /storage/praha1/home/fpartl/.bash_modules...
creating /storage/praha1/home/fpartl/.bash_profile...
creating /storage/praha1/home/fpartl/.bashrc...

Installing custom 3rd party software...
Do you want to install VS Code CLI? (y/n)
...

Installation completed! Have a nice day!

your_name@nympha~$ 
```

The installation script does the following:
1. Asks for your home directory where the `.bash*` scripts will be installed (as symlinks to the `metaenv` repository clone). The default home directory is the current value of the `HOME` environment variable.
2. Furthermore, it creates a `.metaenv_user_conf` file, which is intended for you to edit and customize your metavo environment (not a symlink).
3. If any of the files already exist, the installation script will overwrite them with your consent (consider backing up your old `.metaenv_user_conf` configuration file).

## Update
To update simply navigate to your `metaenv` repository clone and pull changes from `master` branch. Reinstallation is required only when the `.metaenv_user_conf` file structure is changed.
```console
your_name@nympha~$ cd tools/metaenv
your_name@nympha~/tools/metaenv$ git fetch
your_name@nympha~/tools/metaenv$ git reset --hard FETCH_HEAD
your_name@nympha~/tools/metaenv$ ./install.sh # may not be necessary
...
```

## Install on all storages
For convenience, a Python script `setup_homes.py` will run the setup on all storages, excluding `du-cesnet`, `software`, `software.metacentrum.cz`, `singularity.metacentrum.cz`, `projects`, and `ostrava2-archive`. The script checks whether or not you have a directory in the storage's `home`.

Running the script with `--update True` will perform an update wherever you have `metaenv` installed.
The script uses the default settings (pressing `y` and leaving path options empty).

## Setting things up
See comments in your freshly installed `.metaenv_user_conf` file.

Enjoy! :sunglasses:
