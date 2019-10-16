This document describes the process for processed paired tumor/normal WGS samples. Where the process differs for WTS samples instructions are highlighted { _in curly brackets_ }. 

## Move to Spartan

Config files are created with [bcbioSetup_Single.Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_Single.Rmd) { [_bcbioSetup_WTS_Single.Rmd_](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_WTS_Single.Rmd) } and moved to Spartan:

`scp -r BATCHFILES spartan:/data/cephfs/punim0010/data/Transfer/raijin/`

## Spartan automation

On Spartan, the `umccr` user executes three steps:

* executing the "staging" driver scripts that copy FASTQs from a local S3 object store, `s3://umccr-fastq-data-prod/`, to `/data/cephfs/punim0010/data/Transfer/raijin_hofmann/`, renaming them as necessary
* sync the resulting folder structure to a Raijin project folder
* clean up and remove the linked data

It is recommended to generate your own private staging folder even when using the `umccr` user to avoid overwriting concurrent transfers from other group members. The process translates to 

`sudo -i -u umccr`

`conda activate aws`

`find /data/cephfs/punim0010/data/Transfer/raijin_hofmann/ -name *files.sh* -execdir sh {} \;`

`rsync -aPL --append-verify --remove-source-files /data/cephfs/punim0010/data/Transfer/raijin_hofmann/ omh563@r-dm.nci.org.au:/g/data3/gx8/projects/PROJECTDIR`

`find /data/cephfs/punim0010/data/Transfer/raijin_hofmann/* -type d -empty -delete`

As a general precaution it makes sense to check the FASTQs being transferred, particularly for top-up samples. The LIMS is in flux, and name changes could result in samples being overwritten.


## NCI automation

On Raijin driver script templates are found in `/g/data3/gx8/projects/std_workflow/scripts`. Copy the relevant scripts to the current working directory and replace the `PROJEC` placeholder at the top of the script with the current project. For WGS tumor/normal start with:

`sh config_bcbio.sh` { _`config_bcbio_wts`_ }

This will set up the folder structure, merge input files (in the case of top-ups) and create run scripts. It makes use of `/g/data3/gx8/projects/std_workflow/merge.sh` { _`merge_wts.sh`_ } which is were changes to to the workflow YAML could be implemented (e.g., switching from `std_workflow_cancer.yaml` to `std_workflow_cancer_ffpe.yaml`, or to hg38).

The resulting run scripts can be submitted with:

`find ./2019* -name run.sh -and -not -path "*/data/*" -execdir qsub {} \;`

The output can be monitored with:

`watch -d -n 300 'find 2019*/ -maxdepth 4 -name bcbio-nextgen-debug.log -path "*/log/*" -and -not -path "*/data/*" -and -not -path "*/bcbiotx/*" 2>/dev/null | xargs tail -n 2'`

Cromwell configs get written at the same time and can be run instead of the native bcbio backend with:

`find ./2019* -name run_cromwell.sh -and -not -path "*/data/*" -execdir qsub {} \;`

Cromwell logs can be monitored with:

`watch -d -n 300 'find 2019*/ -maxdepth 4 -name *-cromwell.log -and -not -path "*/data/*" -and -not -path "*/bcbiotx/*" 2>/dev/null | xargs tail -n 2'`

After bcbio finishes the results _can_ be post-processed with `umccrise` which follows the same configuration approach with the `config_umccrise.sh` script. Copy it to the project directory, change PROJECTNAME and run it, then follow the progress with:

`watch -d -n 300 'find 2019*/ -maxdepth 5 -name *snakemake*.log -path "*/umccrised/*" 2>/dev/null | xargs tail -n 2'`

This should only be done for debugging purposes, though; for the production pipeline follow the steps below to organize data and upload to AWS S3.

{ _WTS data does not need to be post-processed, but it is recommended to use the `draw_fusions_GRCh37.sh` script to add visualisations to the existing results. The script is configured in the usual way, but needs to be run on an interactive node due to compute constraints on the login node._ }


## Organise results & upload to S3

At the end of the run organise data into one place via `organize_s3.sh`. At this stage things get a bit manual, unfortunately - data in the newly created `s3` folder need to be organized by their project using the `ProjectName` column from Google-LIMS, or the `project_name` column in the sample CSV:

```
./s3
    /Patients
             /SBJ00162
             /SBJ00177
    /Avner
             /...
```

In practice this just means creating the matching folder and `mv`ing the sample directories already present in `s3` into the right, newly-created folders. 

**Note:** this assumes a matching project folder already exists on S3. If that's not the case set one up prior to running the upload script, e.g.:

```
touch new_project
aws s3 cp new_project s3://umccr-primary-data-prod/NEW_PROJECT_NAME/
```

After this start an interactive job (`qsub -I -P gx8 -q copyq -l walltime=12:00:00,ncpus=1,wd,mem=32G,jobfs=100GB`), authenticate (`ssoaws`), assume the `prod_operator` role and run `upload_s3.sh` { _`upload_s3_wts.sh`_ } to upload all relevant data to the S3 results bucket and trigger umccrise on AWS Batch. Progress there can be monitored with [awsbw](https://github.com/jgolob/awsbw). 

{ _The WTS script does not yet trigger an automatic postprocessing step._ }


## Notes

To test what umccrise version is active on AWS run

```
$ aws batch describe-job-definitions --job-definition-name umccrise_job_prod --status ACTIVE --query "jobDefinitions[*].containerProperties.image"
[
    "umccr/umccrise:0.15.12"
]
```



