#!/bin/bash
#PBS -P gx8
#PBS -q normal
#PBS -l walltime=96:00:00
#PBS -l mem=2GB
#PBS -l ncpus=1
#PBS -l software=bcbio
#PBS -l wd
export PATH=/g/data/gx8/local/production/bin:/g/data3/gx8/local/production/bcbio/anaconda/bin:/opt/bin:/bin:/usr/bin:/opt/pbs/default/bin
bcbio_nextgen.py ../config/bcbio_system_normal.yaml ../config/WORKFLOW.yaml -n 128 -q normal -s pbspro -t ipython -r 'walltime=48:00:00;noselect;jobfs=100GB' --retries 1 --timeout 900
