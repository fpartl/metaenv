# metaenv

Small tools for working on [MetaCentrum](https://docs.metacentrum.cz/): sessions on the nodes, job outputs and
Singularity images of projects. Every tool is a standalone script with `set -euo pipefail`; the comment at its top
shows how to use it, with examples. The tools that run anywhere are in [`bin/`](bin), the ones for MetaCentrum only
(PBS, Singularity) in [`bin/metacentrum/`](bin/metacentrum).

| command | where | what it does |
|---|---|---|
| `is-run [options]` | frontend | a session on a node, prints how to connect (SSH, VS Code); options by `-h` |
| `wjo <id>`, `wje <id>` | frontend | output / errors of a job: `tail -f` while it runs, `less` once finished |
| `job-info <id> <attribute>...` | frontend | attributes of a job (also a finished one), one per line |
| `sinshell <image.sif> [command...]` | node | a shell or a command in an image, with the GPUs and the job's scratch |
| `docker-to-sif <archive.tar> [out.sif]` | node | `.sif` from a `docker save` archive, built in the job's scratch |
| `sif-tag [project-dir]` | anywhere | fingerprint of the environment, `sha256(uv.lock + Dockerfile)[:12]` |
| `sif-build [-n NAME] <images>` | your machine | `<images>/<name>-<tag>.sif` from the Dockerfile (Docker + Apptainer) |
| `qsub -v REPO,COMMIT,IMAGES,CMD sif-job` | node (PBS) | a command of a project at an exact commit, in its image |

## Installation

**MetaCentrum.** On your frontend (e.g. nympha, home `/storage/plzen1/home/$USER`), clone into its home and put it
into its `~/.bashrc`:

```bash
git clone https://github.com/fpartl/metaenv.git ~/tools/metaenv
~/tools/metaenv/install.sh
```

`install.sh` puts a block (`# >>> metaenv >>>`) at the top of `~/.bashrc`, before any part for interactive shells
only, so the tools are on `PATH` also in `ssh <frontend> is-run …`. Running it again replaces the block (and removes
the block of the old metaenv); the previous file is kept as `.bashrc.metaenv.bak`. Update by `git pull`.

**From the old metaenv** (`src/*.sh`, the block `# metaenv stuff`): run `install.sh` right after the `git pull` (or
checkout). Until then the old block sources files that no longer exist and every shell prints errors, also `scp`.
The old `~/.metaenv_user_conf` is not used any more and can be deleted.

Only this one home is set up. Every storage has its own home and a node logs you into the one nearest to it, so
`is-run` prints an SSH command that switches the shell on the node to this home (`export HOME=…; exec bash -l`), with
its `.bashrc`, metaenv and configuration.

**Your machine.** Clone anywhere and run `install.sh` the same way. `metaenv.sh` puts `bin/metacentrum/` on `PATH` only
when `HOME` is on `/storage` (MetaCentrum), so your machine gets just `bin/`: `sif-tag` and `sif-build`. `sif-build`
needs Docker and [Apptainer](https://apptainer.org/) (`sudo dnf install apptainer`).

## Sessions

```bash
is-run                       # 2 CPUs, 16 GB RAM, 32 GB local scratch, no GPU, 12 hours
is-run -g 1 -m 32            # with a GPU, the default queue routes it to the GPU queues
is-run -w 48 -l cluster=konos
```

The session is a batch job that only sleeps and holds the resources. `is-run` first prints the final `qsub` command
and submits it only after you confirm it (`y`). Then it waits until the job runs and prints the node, its scratch and
the commands to connect (SSH, VS Code), which open the folder `is-run` was started from, so start it in the project you
work on. Ctrl+C stops the waiting, not the job. Connect as many times as you like, a dropped connection does not end
the session; end it by `qdel <id>` (or let the walltime run out).

### Temporary files in the scratch

`/tmp` of a node has a small limit and some libraries write large intermediate results there. In a job (the SSH
session of `is-run`), metaenv therefore points `TMPDIR`, `SINGULARITY_TMPDIR` and `SINGULARITY_CACHEDIR` into the
job's scratch by itself; `tmp-to-scratch` does the same by hand, e.g. after `SCRATCHDIR` changed. `sif-job` sets
`TMPDIR` on its own.

A PBS job starts in the node's own home, without metaenv, and so does the terminal of VS Code. Your own job script
(or that terminal) gets it by `source /storage/plzen1/home/$USER/tools/metaenv/metaenv.sh`.

### SSH to the nodes from your machine

The nodes are reached through a frontend (`ProxyJump`): the frontend only forwards the connection, so nothing runs on
it. Both hops authenticate by your Kerberos ticket (`kinit $USER@META`), so `~/.ssh/config` needs:

```ssh-config
Host nympha
    HostName nympha.zcu.cz

# MetaCentrum nodes (add the domain of a node that is not covered)
Host *.metacentrum.cz *.cesnet.cz *.cerit-sc.cz *.fav.zcu.cz *.meta.zcu.cz *.muni.cz *.cuni.cz *.elixir-czech.cz
    ProxyJump nympha

Host nympha *.metacentrum.cz *.cesnet.cz *.cerit-sc.cz *.fav.zcu.cz *.meta.zcu.cz *.muni.cz *.cuni.cz *.elixir-czech.cz
    GSSAPIAuthentication yes
    GSSAPIDelegateCredentials yes
    GSSAPIKeyExchange yes
```

`GSSAPIKeyExchange` verifies the host by Kerberos, so a new node does not ask to accept its host key. The patterns
match the name you type, so aliases (`nympha`) are not affected; a machine that is not a node but matches by its full
name (e.g. your server `*.fav.zcu.cz`) needs an alias or `!<its name>` in the patterns.

VS Code (Remote - SSH) then opens a folder on the node directly, `code --remote ssh-remote+<node> <folder>`, the
command `is-run` prints. VS Code does not run that command, so its terminal starts in the node's own home, without
metaenv.

## Images of projects

A project is run on MetaCentrum in a Singularity image of its environment, named by its fingerprint:
`<images>/<project>-<tag>.sif` with `tag = sif-tag` = the first 12 hex digits of sha256 of `uv.lock` followed by
`Dockerfile`. Any change of the dependencies therefore means a new image, and a commit always finds the image of its
own environment; old images stay for old commits.

The image holds only the environment, outside `/app` (e.g. `UV_PROJECT_ENVIRONMENT=/opt/venv` with the project
installed editable from `/app`); `sif-job` mounts the clone of the commit over `/app`.

`<images>` is a folder of your choice, nothing creates it for you. An image takes one to several GB, so put it on the
storage of your project rather than into your home, and create it once:

```bash
mkdir -p /storage/<storage>/projects/<project>/images
cd ~/projects/<project>
sif-build /storage/<storage>/projects/<project>/images     # does nothing when the image exists
```

Without Apptainer, `docker save` the image and convert it in a job on MetaCentrum by `docker-to-sif` (`sif-build`
prints the commands).

### Jobs

```bash
qsub -l select=1:ncpus=4:mem=16gb:scratch_local=20gb -l walltime=4:00:00 \
    -v REPO=<git url or path>,COMMIT=<sha>,IMAGES=<dir>,CMD='<command>',OUTPUT_TO=<dir> \
    /storage/plzen1/home/$USER/tools/metaenv/bin/metacentrum/sif-job
```

`sif-job` clones `REPO` into the scratch, checks out `COMMIT`, picks the image of that commit (fails at once when it
is missing), runs `CMD` in it at `/app` and copies `OUTPUT` (default `output`) into `OUTPUT_TO`. The scratch is
cleaned at the end, unless the copying failed. `NAME` overrides the name of the image (default: the repository name).

## Development

`pre-commit install` once; the hooks run `shellcheck` on the scripts.
