#!/bin/bash
#PBS -l select=1:ncpus=1:mem=8gb:scratch_local=10gb
#PBS -l walltime=4:00:00
#PBS -N my_job
# TODO: the resources and the name above (ngpus=1 for a GPU), what the job does here.
#
# A job of a uv project: the project at the commit COMMIT, in its uv environment, both in the job's scratch; needs
# nothing of metaenv (docs/job_scripts.md). Submit it from the root of the repository, after `uv sync` there (it fills
# uv's cache the job takes the environment from):
#
#   qsub -v COMMIT=$(git rev-parse HEAD),EXPERIMENT=first app/meta_worker.sh
#   for i in {1..100}; do qsub -v COMMIT=$(git rev-parse HEAD),EXPERIMENT=first app/meta_worker.sh; done

set -euo pipefail
# TODO: the variables of your command, given by qsub -v
: "${COMMIT:?missing COMMIT}" "${EXPERIMENT:?missing EXPERIMENT}"
trap clean_scratch EXIT TERM

# the project at COMMIT in the scratch, so that changes after qsub do not get in; its environment there too, only from
# uv's cache in the home of the frontend (PBS gives the node's own one), so no git server is needed. uv from its
# installer (~/.local/bin) or `pixi global` (~/.pixi/bin); a batch job does not read ~/.bashrc.
export HOME=$PBS_O_HOME TMPDIR=$SCRATCHDIR PATH=$PBS_O_HOME/.local/bin:$PBS_O_HOME/.pixi/bin:$PATH
export UV_PROJECT_ENVIRONMENT=$SCRATCHDIR/venv UV_LINK_MODE=copy UV_OFFLINE=1 UV_FROZEN=1
git clone --quiet "$PBS_O_WORKDIR" "$SCRATCHDIR/repo"
cd "$SCRATCHDIR/repo"
git checkout --quiet --detach "$COMMIT"
echo "job $PBS_JOBID on $(hostname -f): commit $COMMIT"

# TODO: your command; results to a folder on the storage (an absolute path), the scratch is cleaned at the end
results=/storage/plzen1/home/$USER/results/$EXPERIMENT
mkdir -p "$results"
uv run python app/main.py --experiment "$EXPERIMENT" --output "$results/${PBS_JOBID%%.*}"
