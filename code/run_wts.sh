#!/bin/bash
#PBS -P gx8
#PBS -q normal
#PBS -l walltime=12:00:00
#PBS -l mem=2GB
#PBS -l ncpus=1
#PBS -l software=bcbio
#PBS -l wd
#PBS -l storage=gdata/gx8
export PATH=/g/data3/gx8/local/development/bcbio/anaconda/bin:/g/data/gx8/local/development/bin:/opt/bin:/bin:/usr/bin:/opt/pbs/default/bin
bcbio_nextgen.py ../config/bcbio_system_normalgadi.yaml ../config/WORKFLOW.yaml -n 24 -q normal -s pbspro -t ipython -r 'walltime=10:00:00;noselect;jobfs=100GB;storage=scratch/gx8+gdata/gx8' --retries 1 --timeout 900
