# A-Z of running samples through the bcbio workflow

## 1. Create config files for the samples to be run

If this is for batches, follow the [bcbio Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup.Rmd).

If this is for single patients, follow the [bcbioSetup_Single Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_Single.Rmd)

If this is for WTS, follow the [bcbioSetup_WTS](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_WTS.Rmd)

Each of these workflows should result in two files: TIMESTAMP_PROJECT.csv and TIMESTAMP_PROJECT.sh file, per subject folder.

## 2. Running the samples

### 2a. Using Spartan

If this is for **testing**, follow these guidelines to run the samples on **Spartan**. Note that the versions of bcbio and umccrise may be out of date on Spartan and subsequently superseded (check with `umccrise --version` and `bcbio_nextgen.py -v`).

`scp -r TIMESTAMP_PROJECT* yourUserName@spartan.hpc.unimelb.edu.au:/data/cephfs/punim0010/projects/PROJECTDIR`

`sh TIMESTAMP_PROJECT_files.txt`  
`cp /data/cephfs/punim0010/projects/std_workflow/merge.sh .`  
`vi merge.sh`  
`sbatch merge.sh`  
`mv *-merged.csv ..; cd ..`  
`export PATH=/data/projects/punim0010/local/stable/bin:$PATH`  
`bcbio_nextgen.py -w template ../../std_workflow/std_workflow_cancer.yaml 2019-05-15T0319_Avner_WGS-merged.csv data/merged/*.gz`  
`cp ../../std_workflow/run.sh 2019-05-15T0319_Avner_WGS-merged/work; cd 2019-05-15T0319_Avner_WGS-merged/work`  
`vi run.sh`  
`sbatch run.sh`  
`less +F log/bcbio-nextgen-debug.log`  
`export PATH=/data/projects/punim0010/local/stable/bin:$PATH`  
`sbatch run.sh`  

Point `umccrise` at the `final` directory:  

`source /data/cephfs/punim0010/extras/umccrise/load_umccrise.sh`  
`export AWS_PROFILE=umccr`  
`umccrise . -j 16 --cluster-auto`  

### 2b Raijin

Copy the folders created to spartan.

`scp -r TIMESTAMP_PROJECT/ yourUserName@spartan.hpc.unimelb.edu.au:/data/cephfs/punim0010/data/Transfer/raijin/`  

(Note it may be preferable to upload the folders into a new directory created within that location, if multiple users are using the directory simultaneously).

Log into Spartan, change to `umccr` user:

`sudo -i -u umccr`
`cd /data/cephfs/punim0010/data/Transfer/raijin/`
`find /data/cephfs/punim0010/data/Transfer/raijin/ -name *files.sh* -execdir sh {} \;`

(Log into Spartan to copy `TIMESTAMP_PROJECT/` to Raijin)  

`rsync -aPL --append-verify --remove-source-files /data/cephfs/punim0010/data/Transfer/raijin/TIMESTAMP_PROJECT/ yourUserName@r-dm.nci.org.au:/g/data3/gx8/projects/TIMESTAMP_PROJECT`

**Log into raijin.**

Change into the new project directory created in the last step:

`cp /g/data3/gx8/projects/std_workflow/scripts/config_bcbio.sh .`

Replace the `PROJECTNAME` placeholder in this file with the current project.

`sh config_bcbio.sh`

This will set up the folder structure, merge input files (in the case of top-ups) and create run scripts which can be submitted with:

`find ./2019* -name run.sh -and -not -path "*/data/*" -execdir qsub {} \;`

The output can be monitored with:

`watch -d -n 300 'find 2019*/ -maxdepth 4 -name bcbio-nextgen-debug.log -path "*/log/*" -and -not -path "*/data/*" -and -not -path "*/bcbiotx/*" 2>/dev/null | xargs tail -n 2'`

After bcbio finishes the results are post-processed with `umccrise` which follows the same configuration approach with the `config_umccrise.sh` script. Copy it to the project directory:

`cp /g/data3/gx8/projects/std_workflow/scripts/config_bcbio.sh .`

change PROJECTNAME and run it, then follow the progress with:

`watch -d -n 300 'find 2019*/ -maxdepth 5 -name *snakemake*.log -path "*/umccrised/*" 2>/dev/null | xargs tail -n 2'`

## Organise results & upload to S3

At the end of the run organise data into one place via `organize_results.sh`:

`cp /g/data3/gx8/projects/std_workflow/scripts/organize_results.sh .`

(Confirm the script is pointing at the correct directory).
Reports for Trello end up in `reports`, the data for S3 in `sync`. 
(Make sure you have followed the directions [in the wiki](https://github.com/umccr/wiki/blob/master/computing/cloud/aws.md)
for setting up your AWS credentials).
Start an interactive job (`qsub -I -P gx8 -q copyq -l walltime=12:00:00,ncpus=1,wd,mem=32G,jobfs=100GB`), authenticate (`ssoaws`).  You will need to assume the `fastq_data_uploader` role.  If you **do not** have access to this role, talk to Florian.
Then run:

`aws s3 sync --no-progress --dryrun . s3://umccr-primary-data-prod/PROJECT/`

... to upload all relevant data to the S3 results bucket.

