#!/bin/bash
#PBS -P gx8
#PBS -q normalsp
#PBS -l walltime=96:00:00
#PBS -l mem=4GB
#PBS -l ncpus=1
#PBS -l software=bcbio
#PBS -l wd
export PATH=/g/data/gx8/local/production/bin:/g/data3/gx8/local/production/bcbio/anaconda/bin:/opt/bin:/bin:/usr/bin:/opt/pbs/default/bin  
bcbio_vm.py cwlrun cromwell ../config/WORKFLOW-workflow --no-container -q normalbw -s pbspro -r  'walltime=48:00:00;noselect;jobfs=100GB' 
