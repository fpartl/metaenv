# metaenv

Command-line tools that make everyday work on [MetaCentrum](https://docs.metacentrum.cz/) less tedious: interactive
sessions on the compute nodes you can connect to by SSH or VS Code, a quick overview of your jobs, and reproducible
runs of your projects at an exact commit, optionally in a Singularity image of their environment.

```bash
job session -g 1 -m 32       # a node with a GPU and 32 GB RAM; prints how to connect (SSH, VS Code)
job shell <id>               # from a frontend: a shell inside a job on its node
job list                     # your jobs: state, node, hours used, folder
job info -e <id>             # how much of the requested CPUs and memory a job really uses
job log out <id>             # follow the output of a running job
job kill <id>                # end a job (after a confirmation)
job info **<Tab>             # pick a job in fzf; Tab also completes commands, job ids and images
```

## Why

- **Sessions you can actually work in.** `job session` submits a job that just holds the resources and tells you
  where it runs. `ssh <node>` or VS Code Remote then land *inside* the job, so whatever you run counts against its
  CPUs and memory, not against the node shared with other users. A dropped connection does not end the session.
- **Less PBS typing.** Listing, inspecting, extending and killing jobs, or reading their logs, takes one short command.
  Tab completes the subcommands, the ids of your jobs (newest first, also in `qdel` and `qextend`), `.sif` images and
  `.tar` archives. With [fzf](https://github.com/junegunn/fzf) loaded in your shell, `job info **<Tab>` opens a list of
  your jobs with their state, name and queue and puts the id of the chosen one on the command line.
- **Reproducible runs.** A job clones your repository at a given commit, so hundreds of queued jobs run exactly the
  code they were submitted with, whatever happens in your working tree meanwhile.
- **Images of environments.** `sif` builds a Singularity image named by a fingerprint of `uv.lock` and `Dockerfile`,
  so every commit finds the image of its own environment.

## Installation

Clone the repository and run the installer, both on your MetaCentrum frontend (e.g. nympha) and on your own machine:

```bash
git clone https://github.com/fpartl/metaenv.git ~/tools/metaenv
~/tools/metaenv/setup.sh
```

The installer adds a small block to your `~/.bashrc` (a backup is kept) and can be run again at any time; update by
`git pull`. On MetaCentrum it puts `job` and `sif` on your `PATH`, on your machine `sif` (with
[Apptainer](https://apptainer.org/), also `sif build` and `sif shell`). To get from your machine into your jobs by
`ssh <node>` or VS Code, add a few lines to `~/.ssh/config`: they run `job shell` on the node for you
([docs/ssh.md](docs/ssh.md)). Tab completion is set up by the installer too; for the job picker, load fzf in your
`~/.bashrc` (`eval "$(fzf --bash)"`). Details, including migrating from the old metaenv, are in
[docs/installation.md](docs/installation.md).

## Commands

### `job`: jobs on MetaCentrum

`job` alone lists its subcommands. Each is a script in [`libexec/job/`](libexec/job) with its usage and examples in
the comment at its top.

| command | where | what it does |
|---|---|---|
| `job session [options]` | frontend | a session on a node, prints how to connect (SSH, VS Code); options by `-h` |
| `job list [-x]` | frontend | your jobs: state, name, node, hours of the walltime used, folder; `-x` with finished |
| `job info [-c] [-e\|-ee] [-v] [id]` | frontend, job | a job (also finished); `-c` connect, `-e` its usage, `-v` all |
| `job shell [id]`, `job attach` | node, frontend, `ssh <node>` | a shell inside your job (RemoteCommand) |
| `job extend [id] <hours>` | frontend, job | more hours for a running job (`qextend`) |
| `job kill <id>...` | frontend | ends jobs (`qdel`) after showing which ones and a confirmation |
| `job log out\|err <id>`, `wjo`, `wje` | frontend | output / errors of a job: `tail -f` while it runs, else `less` |

Without an id, `job info`, `job extend` and `job shell` take the job you are in (`job shell`: your session on the node).

### `sif`: images of projects

`sif` alone lists its subcommands. Each is a script in [`libexec/sif/`](libexec/sif) with its usage and examples in
the comment at its top.

| command | where | what it does |
|---|---|---|
| `sif tag [project-dir]` | anywhere | fingerprint of the environment, `sha256(uv.lock + Dockerfile)[:12]` |
| `sif build [-n NAME] <images>` | your machine | `<images>/<name>-<tag>.sif` from the Dockerfile (Docker + Apptainer) |
| `sif shell <image.sif> [command...]` | node, your machine | a shell or command in an image, with GPUs and scratch |
| `sif from-docker <archive.tar> [out.sif]` | node | `.sif` from a `docker save` archive, built in the job's scratch |
| `qsub -v REPO,COMMIT,IMAGES,CMD …/libexec/sif/job` | PBS | a command of a project at an exact commit, in its image |

## Documentation

| topic | what you find there |
|---|---|
| [Installation](docs/installation.md) | what `setup.sh` does, the old metaenv, your machine, Tab completion |
| [Sessions](docs/sessions.md) | `job session`, `job shell` inside a job, temporary files in the scratch |
| [SSH](docs/ssh.md) | `ssh <node>` and VS Code from your machine into your job, git and ssh on the nodes |
| [Job scripts of uv projects](docs/job_scripts.md) | a job at an exact commit by plain `qsub`, a script to copy |
| [Images of projects](docs/images.md) | Singularity images by `sif`, a job in the image of a commit |

## Development

The only prerequisite is [uv](https://docs.astral.sh/uv/getting-started/installation/). The scripts are plain Bash;
[`pyproject.toml`](pyproject.toml) only pins the development tools (`pre-commit`).

```bash
git clone https://github.com/fpartl/metaenv.git
cd metaenv
./.githooks/init.sh
```

`init.sh` runs `uv sync` (a `.venv` with pre-commit) and `uv run pre-commit install`, so every commit checks the
scripts by `shellcheck` and a few other hooks ([`.pre-commit-config.yaml`](.pre-commit-config.yaml)). To check all
files at once, run `uv run pre-commit run --all-files`.
