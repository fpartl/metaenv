# metaenv &mdash; MetaCentrum environment setup

Automatic module initialization, easy export of environment variables, singularity integration, interactive sessions
helper, live output of your jobs and much more!

## Installation
Connect to your favorite [MetaVO frontend machine](https://docs.metacentrum.cz/computing/frontends/) via SSH and run the
following commands:
```bash
# ssh user@zenith.cerit-sc.cz
mkdir tools && cd tools # recommended destination
git clone https://github.com/fpartl/metaenv.git
cd metaenv
chmod +x install.sh
./install.sh
```

The installation script does the following:
1. Asks for your home directory where the `.bash*` scripts will be replaced/modified. The default home directory is the
   current value of the `HOME` environment variable.
2. Creates the `.metaenv_user_conf` file, which is intended for you to customize your metaenv configurations. If the
   `.metaenv_user_conf` file already exists, the installation script will overwrite it with your consent.
3. With your consent replaces your actual `.bashrc`, `.bash_profile` and `.bash_login` files with the recommendations
   from the official [MetaVO
   documentation](https://wiki.metacentrum.cz/wiki/U%C5%BEivatel:Mmares/Co_si_d%C3%A1t_do_.bashrc%3F). This step can be
   skipped if you want to keep your current configuration but the Metaenv package is not guaranteed to work properly.
4. Adds the necessary lines (delimited by `# metaenv stuff`) to the `.bashrc` file to source the `.metaenv_user_conf`
   file and to initialize the Metaenv environment.
5. Installs some 3rd party useful software like [VS Code](https://code.visualstudio.com/) server for remote development and 
   [Miniconda](https://docs.anaconda.com/free/miniconda/index.html) for Python project management.

### Setting things up
See comments in your freshly installed `.metaenv_user_conf` file.

### Update
To update simply navigate to your `metaenv` repository clone and pull changes from `master` branch. Reinstallation is
required only when the `.metaenv_user_conf` file structure is changed.
```bash
cd tools/metaenv # or wherever you cloned the repository
git fetch
git reset --hard FETCH_HEAD
```

## Usage


Enjoy! :sunglasses:
