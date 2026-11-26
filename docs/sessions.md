# Sessions

```bash
job session                  # 2 CPUs, 16 GB RAM, 32 GB local scratch, no GPU, 8 hours
job session -g 1 -m 32       # with a GPU, the default queue routes it to the GPU queues
job session -w 48 -l cluster=konos
```

The session is a batch job that only sleeps and holds the resources. `job session` first prints the final `qsub`
command and submits it only after you confirm it (`y`). Then it waits until the job runs and prints the node, its
scratch and the commands to connect (SSH, VS Code), which open the folder `job session` was started from, so start it
in the project you work on. Ctrl+C stops the waiting, not the job; `job info -c <id>` prints it all again (`job list`
shows the id). Connect as many times as you like, a dropped connection does not end the session; end it by
`job kill <id>` (or let the walltime run out). `job info -e <id>` shows how much of the requested CPUs and memory it
uses (as PBS measures them), to size the next one; `-ee` also of the scratch and GPUs, measured on the node (`du`,
`nvidia-smi` inside the job), which takes longer.

A job is no container: its processes run on the node next to those of other users, PBS only puts them into a cgroup
with the CPUs and memory of the job (beyond the memory the kernel kills a process of that job, not of others). An SSH
login to the node is not part of the job, it would have all CPUs and memory of the node. `job shell` therefore finds
your session on the node and starts the shell inside it (`pbs_attach`), with the home metaenv is installed in, the
job's scratch and the folder `job session` was started from; all you run from it counts to the job. On a frontend
`job shell <id>` connects to the node of the job first; from your machine `ssh <node>` and VS Code run it by
themselves (RemoteCommand, [ssh.md](ssh.md)), VS Code with its server, terminals and extensions inside the job.

## Temporary files in the scratch

`/tmp` of a node has a small limit and some libraries write large intermediate results there. In a job (the SSH
session of `job session`), metaenv therefore points `TMPDIR`, `SINGULARITY_TMPDIR` and `SINGULARITY_CACHEDIR` into the
job's scratch by itself; `tmp-to-scratch` does the same by hand, e.g. after `SCRATCHDIR` changed. The job script of
`sif` (`libexec/sif/job`) sets `TMPDIR` on its own.
