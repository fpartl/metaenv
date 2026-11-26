# Images of projects

A project is run on MetaCentrum in a Singularity image of its environment, named by its fingerprint:
`<images>/<project>-<tag>.sif` with `tag` = `sif tag` = the first 12 hex digits of sha256 of `uv.lock` followed by
`Dockerfile`. Any change of the dependencies therefore means a new image, and a commit always finds the image of its
own environment; old images stay for old commits.

The image holds only the environment, outside `/app` (e.g. `UV_PROJECT_ENVIRONMENT=/opt/venv` with the project
installed editable from `/app`); the job (below) mounts the clone of the commit over `/app`.

`<images>` is a folder of your choice, nothing creates it for you. An image takes one to several GB, so put it on the
storage of your project rather than into your home, and create it once:

```bash
mkdir -p /storage/<storage>/projects/<project>/images
cd ~/projects/<project>
sif build /storage/<storage>/projects/<project>/images     # does nothing when the image exists
```

Without Apptainer, `docker save` the image and convert it in a job on MetaCentrum by `sif from-docker` (`sif build`
prints the commands).

## Jobs

```bash
qsub -l select=1:ncpus=4:mem=16gb:scratch_local=20gb -l walltime=4:00:00 \
    -v REPO=<git url or path>,COMMIT=<sha>,IMAGES=<dir>,CMD='<command>',OUTPUT_TO=<dir> \
    /storage/plzen1/home/$USER/tools/metaenv/libexec/sif/job
```

The job clones `REPO` into the scratch, checks out `COMMIT`, picks the image of that commit (fails at once when it
is missing), runs `CMD` in it at `/app` and copies `OUTPUT` (default `output`) into `OUTPUT_TO`. The scratch is
cleaned at the end, unless the copying failed. `NAME` overrides the name of the image (default: the repository name).
