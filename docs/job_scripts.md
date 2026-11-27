# Job scripts of uv projects

A project whose dependencies are all Python packages needs no image: uv installs them on the node, PyTorch's CUDA
wheels bring CUDA along and need only the driver of the node. Develop and debug it in a session (`job session -g 1`,
VS Code), run it by a job script of its own, submitted by plain `qsub`. The script needs nothing of metaenv, so it
runs for anyone and at any old commit. Copy [`meta_worker.sh`](meta_worker.sh) into the project and fill in its
`TODO`s:

```bash
cd <project>                               # the root of the repository
cp ~/tools/metaenv/docs/meta_worker.sh app/    # once, then fill in its TODOs
uv sync                                    # fills uv's cache
qsub -v COMMIT=$(git rev-parse HEAD),EXPERIMENT=first app/meta_worker.sh
job log out <id>                           # its output; job list: the ids
```

What the script does and why:

- `PBS_O_WORKDIR` and `PBS_O_HOME` are the folder `qsub` was run in and its home: submit from the root of the
  repository.
- The clone of `COMMIT`: hundreds of jobs waiting in the queue run the commit they were submitted at, whatever
  happens in the working tree meanwhile.
- The environment in the scratch, on the node's disk, not the project's `.venv` on the network storage. The cache is
  on another file system, hence `UV_LINK_MODE=copy`.
- `UV_OFFLINE`: no git server, no SSH keys on the node; dependencies from a git server come from uv's cache too. A
  dependency missing in the cache ends the job at once, before the work; `uv sync` of the project at that commit, on
  a frontend or in a session, puts it there.
- Results go to a folder on the storage (an absolute path), the scratch is cleaned at the end.
