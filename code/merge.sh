#!/bin/bash
#PBS -P gx8
#PBS -q normalsp
#PBS -l walltime=96:00:00
#PBS -l mem=2GB
#PBS -l ncpus=1
#PBS -l software=bcbio
#PBS -l wd
bcbio_prepare_samples.py --out merged --csv kolling.csv -n 32 -q normal -s pbspro -t ipython -r 'walltime=48:00:00;noselect' --retries 1 --timeout 900