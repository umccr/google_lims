#!/bin/bash
#PBS -P gx8
#PBS -q express
#PBS -l walltime=4:00:00
#PBS -l mem=2GB
#PBS -l ncpus=1
#PBS -l software=bcbio
#PBS -l wd

# Merge samples and create new CSV summary
bcbio_prepare_samples.py --out merged --csv TEMPLATE.csv -n 2 -q express -s pbspro -t ipython -r 'walltime=4:00:00;noselect' --retries 1 --timeout 900

# Generate the bcbio config from a standard workflow template
bcbio_vm.py template --systemconfig bcbio_system_normalbw.yaml /g/data/gx8/projects/std_workflow/std_workflow_cancer_ffpe.yaml BATCH-merged.csv 

# Also generate CWL version
bcbio_vm.py cwl --systemconfig bcbio_system_normalbw.yaml CLEAN-merged/config/CONFIG-merged.yaml

# Set up run scripts
sed "s|WORKFLOW|CONFIG-merged|" /g/data/gx8/projects/std_workflow/run.sh > CLEAN-merged/work/run.sh

mkdir CLEAN-merged/work-cromwell
sed "s|WORKFLOW|CONFIG-merged|" /g/data/gx8/projects/std_workflow/run_cromwell.sh > CLEAN-merged/work-cromwell/run_cromwell.sh

# Move to parent directory to separate from input data
cp -rv CLEAN-merged/ ..
cp -rv CLEAN-merged-workflow/ ../CONFIG-merged/config/
cp -rv bcbio_system_normalbw.yaml ../CONFIG-merged/config/ 
