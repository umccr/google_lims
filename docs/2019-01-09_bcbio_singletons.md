## Move to Spartan

Config files are created with [bcbioSetup_Single.Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_Single.Rmd) and moved to Spartan:

`scp -r BATCHFILES spartan:/data/cephfs/punim0010/data/Transfer/raijin/`

## Spartan automation

On Spartan, the `umccr` user executes three steps:

* executing the `ln` driver scripts that (hard)link FASTQs from `/data/cephfs/punim0010/data/Pipeline/prod/Fastq` to `/data/cephfs/punim0010/data/Transfer/raijin/`, renaming them as necessary
* sync the resulting folder structure to a Raijin project folder
* clean up and remove the linked data

This translates to:

`find /data/cephfs/punim0010/data/Transfer/raijin/ -name *files.sh* -execdir sh {} \;`

`rsync -aPL --append-verify --remove-source-files /data/cephfs/punim0010/data/Transfer/raijin/ omh563@r-dm.nci.org.au:/g/data3/gx8/projects/PROJECTDIR`

`find /data/cephfs/punim0010/data/Transfer/raijin/* -type d -empty -delete`

## NCI automation

On Raijin driver script templates are found in `/g/data3/gx8/projects/std_workflow/scripts`. Copy the relevant scripts to the current working directory and replace the `PROJECTNAME` placeholder in the script with the current project. Start with:

`sh config_bcbio.sh`

This will set up the folder structure, merge input files (in the case of top-ups) and create run scripts which can be submitted with:

`find ./2019* -name run.sh -and -not -path "*/data/*" -execdir qsub {} \;`

The output can be monitored with:

`watch -d -n 300 'find 2019*/ -maxdepth 4 -name bcbio-nextgen-debug.log -path "*/log/*" -and -not -path "*/data/*" -and -not -path "*/bcbiotx/*" 2>/dev/null | xargs tail -n 2'`

Cromwell configs get written at the same time and can be run instead of the native bcbio backend with:

`find ./2019* -name run_cromwell.sh -and -not -path "*/data/*" -execdir qsub {} \;`

Cromwell logs can be monitored with:

`watch -d -n 300 'find 2019*/ -maxdepth 4 -name *-cromwell.log -and -not -path "*/data/*" -and -not -path "*/bcbiotx/*" 2>/dev/null | xargs tail -n 2'`

After bcbio finishes the results are post-processed with `umccrise` which follows the same configuration approach with the `config_umccrise.sh` script. Copy it to the project directory, change PROJECTNAME and run it, then follow the progress with:

`watch -d -n 300 'find 2019*/ -maxdepth 5 -name *snakemake*.log -path "*/umccrised/*" 2>/dev/null | xargs tail -n 2'`

## Organise results & upload to S3

At the end of the run organise data into one place via `organize_results.sh`; reports for Trello end up in `reports`, the data for S3 in `sync`. Start an interactive job (`qsub -I -P gx8 -q copyq -l walltime=12:00:00,ncpus=1,wd,mem=32G,jobfs=100GB`), authenticate (`ssoaws`), assume the `fastq-uploader` role and run:

`aws s3 cp --recursive --dryrun . s3://umccr-primary-data-prod/PROJECT/`

... to upload all relevant data to the S3 results bucket.