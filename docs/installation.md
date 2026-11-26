# Installation

**MetaCentrum.** On your frontend (e.g. nympha, home `/storage/plzen1/home/$USER`), clone into its home and put it
into its `~/.bashrc`:

```bash
git clone https://github.com/fpartl/metaenv.git ~/tools/metaenv
~/tools/metaenv/install.sh
```

`install.sh` puts a block (`# >>> metaenv >>>`) at the top of `~/.bashrc`, before any part for interactive shells
only, so the tools are on `PATH` also in `ssh <frontend> job session …`. Running it again replaces the block (and
removes the block of the old metaenv); the previous file is kept as `.bashrc.metaenv.bak`. Update by `git pull`.

**From the old metaenv** (`src/*.sh`, the block `# metaenv stuff`): run `install.sh` right after the `git pull` (or
checkout). Until then the old block sources files that no longer exist and every shell prints errors, also `scp`.
The old `~/.metaenv_user_conf` is not used any more and can be deleted.

Only this one home is set up. Every storage has its own home and a node logs you into the one nearest to it, so
the shell on a node gets this home from `job shell` ([sessions](sessions.md)), with its `.bashrc`, metaenv and
configuration.

**Your machine.** Clone anywhere and run `install.sh` the same way. `shell/metaenv.sh` puts `bin/metacentrum/` on
`PATH` only when `HOME` is on `/storage` (MetaCentrum), so your machine gets just `bin/`: `sif`. `sif build` needs
Docker and [Apptainer](https://apptainer.org/) (`sudo dnf install apptainer`).

## Tab completion

In a terminal, `metaenv.sh` also loads [`shell/completion.bash`](../shell/completion.bash): Tab completes the commands
of `job` and `sif`, then the ids of your jobs that have not finished, as `job list` (newest first; also in `qdel` and
`qextend`; `job log`, `wjo` and `wje` also finished ones, see `job list -x`), `.sif` images and `.tar` archives.
With [fzf](https://github.com/junegunn/fzf) loaded in the shell (`eval "$(fzf --bash)"`), `job info **<Tab>` opens a
list of the jobs with their state, name and queue, and puts the id of the chosen one on the command line.

Aliases are up to you, e.g. `alias ji='job info'` in `~/.bashrc`.
