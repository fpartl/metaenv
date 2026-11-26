# metaenv

Small tools for working on [MetaCentrum](https://docs.metacentrum.cz/): sessions on the nodes, your jobs and
Singularity images of projects, as two commands with subcommands, `job <command>` and `sif <command>` (each without
one lists its commands). Every command is a standalone script with `set -euo pipefail` in [`libexec/`](libexec); the
comment at its top shows how to use it, with examples. `sif` runs anywhere ([`bin/`](bin)), `job` only on MetaCentrum
([`bin/metacentrum/`](bin/metacentrum)).

| command | where | what it does |
|---|---|---|
| `job session [options]` | frontend | a session on a node, prints how to connect (SSH, VS Code); options by `-h` |
| `job list [-x]` | frontend | your jobs: state, name, node, time of the walltime, folder; `-x` also finished ones |
| `job info [-c] [-e\|-ee] [-v] [id]` | frontend, job | a job (also finished); `-c` connect, `-e` its use, `-v` all |
| `job shell [id]`, `job attach` | node, frontend | a shell inside your job; the RemoteCommand of the nodes |
| `job extend [id] <hours>` | frontend, job | more hours for a running job (`qextend`) |
| `job kill <id>...` | frontend | ends jobs (`qdel`) after showing which ones and a confirmation |
| `job log out\|err <id>`, `wjo`, `wje` | frontend | output / errors of a job: `tail -f` while it runs, else `less` |
| `sif tag [project-dir]` | anywhere | fingerprint of the environment, `sha256(uv.lock + Dockerfile)[:12]` |
| `sif build [-n NAME] <images>` | your machine | `<images>/<name>-<tag>.sif` from the Dockerfile (Docker + Apptainer) |
| `sif shell <image.sif> [command...]` | node | a shell or a command in an image, with the GPUs and the job's scratch |
| `sif from-docker <archive.tar> [out.sif]` | node | `.sif` from a `docker save` archive, built in the job's scratch |
| `qsub -v REPO,COMMIT,IMAGES,CMD …/libexec/sif/job` | PBS | a command of a project at an exact commit, in its image |

Without an id, `job info`, `job extend` and `job shell` take the job you are in (`job shell`: your session on the node).

## Installation

On your MetaCentrum frontend (e.g. nympha) and on your machine:

```bash
git clone https://github.com/fpartl/metaenv.git ~/tools/metaenv
~/tools/metaenv/install.sh
```

## Documentation

| | |
|---|---|
| [Installation](docs/installation.md) | what `install.sh` does, the old metaenv, your machine, Tab completion |
| [Sessions](docs/sessions.md) | `job session`, `job shell` inside a job, temporary files in the scratch |
| [SSH](docs/ssh.md) | `ssh <node>` and VS Code from your machine into your job, git and ssh on the nodes |
| [Job scripts of uv projects](docs/job_scripts.md) | a job at an exact commit by plain `qsub`, the snippet to copy |
| [Images of projects](docs/images.md) | Singularity images by `sif`, a job in the image of a commit |

## Development

The only prerequisite is [uv](https://docs.astral.sh/uv/getting-started/installation/); `pre-commit` is a dev
dependency in [`pyproject.toml`](pyproject.toml) (not a Python package, only the tools). After the clone:

```bash
./.githooks/init.sh
```

It runs `uv sync` (the `.venv` with pre-commit) and `uv run pre-commit install`, so every commit checks the scripts by
`shellcheck` and a few other hooks ([`.pre-commit-config.yaml`](.pre-commit-config.yaml)). All files at once:
`uv run pre-commit run --all-files`.
