#!/bin/bash
#PBS -P gx8
#PBS -q normal
#PBS -l walltime=12:00:00
#PBS -l mem=2GB
#PBS -l ncpus=1
#PBS -l software=umccrise
#PBS -l wd
source /g/data/gx8/extras/umccrise/load_umccrise.sh
umccrise final-cromwell -o umccrised-cromwell --no-igv -j 28 --cluster-auto
