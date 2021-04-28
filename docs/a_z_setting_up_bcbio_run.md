# A-Z of running samples through the bcbio workflow

## 1. Create config files for the samples to be run

We are using two standard approaches to fetch data from ICA's GDS store and set up `bcbio` runs on Gadi:

* If this is for single patients, follow the [bcbioSetup_Single_GDS.Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_Single_GDS.Rmd)
* If this is for WTS, follow the [bcbioSetup_WTS_Single_GDS.Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_WTS_Single_GDS.Rmd)

The repository contains additional driver scripts that fetch data from Spartan S3, run batches (e.g., research cohorts) or support UMIs but these are not meant for production. 

The scripts themselves have documentation and should be self-explanatory. They are best run in RStudio after installing the required packages and confirming access to our portal (i.e., working AWS production credentials). Running one of these these workflows should result in a subject folder per subject processed with three files in a `data` folder: `TIMESTAMP_PROJECT.csv`, `TIMESTAMP_PROJECT.sh` file and a `project_name.txt`.


## 2. Copying config files to Gadi

```
scp -r ./TIMESTAMP* yourUserName@gadi-dm.nci.org.au:/g/data3/gx8/projects/LASTNAME_PROJECT/
```

You may have to create the `LASTNAME_PROJECT` folder on Gadi first.

## 3. Staging the input files

Log into Gadi and `cd` into the new project directory. Make sure you have active ICA credentials, e.g., via `ica login && ica projects enter production` and submit the driver scripts that will download the FASTQs from GDS:

```
find ./TIMESTAMP* -name "*_files.sh" -execdir qsub {} \;
```

## 4. Configuring the run 

Once data has finished downloading copy over the relevant configuration file:

* for WGS `cp /g/data3/gx8/projects/std_workflow/scripts/config_bcbio.sh .`
* for WTS `cp /g/data3/gx8/projects/std_workflow/scripts/config_bcbio_wts.sh .`

If a WGS run includes **FFPE* samples it's usually best to move these to a separate project directory and use `config_bcbio_ffpe.sh` to configure these. This results in a reduced workflow set that ensures FFPE samples do not stall and cause delays. 

The `scripts` folder has additional drivers that can be used as needed, e.g., for exome or UMI runs. Replace the `PROJECTNAME` placeholder in the copied config script with the current project, then run it.

`sh config_bcbio.sh` or for WTS samples `sh config_bcbio_wts.sh`

This will set up the folder structure, merge input files (in the case of top-ups) and create run scripts which can be submitted with:

```
$ find ./TIMESTAMP* -name run.sh -and -not -path "*/data/*" -execdir qsub {} \;
```

The output can be monitored with:

```
$ watch -d -n 300 'find TIMESTAMP*/ -maxdepth 4 -name bcbio-nextgen-debug.log -path "*/log/*" -and -not -path "*/data/*" -and -not -path "*/bcbiotx/*" 2>/dev/null | xargs tail -n 2'
```

## 5. Post-processing WTS

All WGS post-processing happens on AWS but for WTS we need to generate Arriba fusion plots outside of bcbio. This step is quite manual and should probably be added to the WTS workflow itself but for now:

* `cp /g/data3/gx8/projects/std_workflow/scripts/draw_fusions_hg38.sh .`
* adjust `PROJECT` name at the top of the script as per usual
* start an interactive instance (`qsub -I -P gx8 -q normal -l walltime=12:00:00,ncpus=24,wd,mem=128G,jobfs=100GB,storage=scratch/gx8+gdata/gx8`) and run the `draw_fusions_hg38.sh` script


## 6. Organise results & upload to S3

After the runs finish successfully (a few hours for WTS, about 24-30h for WGS) data can be moved to AWS S3. Start by organizing results into the required folder structure by copying a helper script into the project directory:

```
$ cp /g/data3/gx8/projects/std_workflow/scripts/organize_s3.sh .
```

Again, adjust `PROJECT` in the first line of the script and run it; results should end up in an `s3` directory. Now data can be moved to S3. Start an interactive job (`qsub -I -P gx8 -q copyq -l walltime=12:00:00,ncpus=1,wd,mem=32G,jobfs=100GB,storage=scratch/gx8+gdata/gx8`) and authenticate (`aws sso login --profile prod`). Add another helper script to the project folder:

* for WGS `cp /g/data3/gx8/projects/std_workflow/scripts/upload_s3.sh .`
* for WTS `cp /g/data3/gx8/projects/std_workflow/scripts/upload_s3_wts.sh .`

As per usual change the `PROJECT` name in the first script line, then run the script. It should iterate over project folders and samples in S3, upload them to AWS, then kick off `umccrise` in the case of WGS samples. The `#biobots` channel on Slack tracks the `umccrise` progress. 

After all of this completes successfully there's some housekeeping to do:

* Update the S3 `Results` locations in the Google LIMs.
* Wipe the project folders from Gadi
* Let Wing-Yee know that the run completed (e.g., in Slack's `#medical-genomics` channel)


## Using Spartan

Samples processed before 2021 are not available on GDS but reside on an S3-compatible object store on Spartan. For the time being current samples are _also_ copied to the same store. This means for samples that need access to older FASTQs - for example, to re-use a previously sequenced normal sample - data can be staged from Spartan.

For this to work please use

* [bcbioSetup_Single.Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_Single.Rmd) for WGS
* [bcbioSetup_WTS_Single.Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_WTS_Single.Rmd) for WTS

Instead of copying the result folders to Gadi copy them to Spartan:

```
scp -r TIMESTAMP* yourUserName@spartan.hpc.unimelb.edu.au:/data/cephfs/punim0010/data/Transfer/raijin/
```

Then log into Spartan and update group read permissions.

```
chmod g+w -R TIMESTAMP*
```

Change to `umccr` user, activate a new aws conda environment and start the download:

```
sudo -i -u umccr
cd /data/cephfs/punim0010/data/Transfer/raijin/
conda activate aws
find /data/cephfs/punim0010/data/Transfer/raijin/ -name *files.sh* -execdir sh {} \;
```

Copy `TIMESTAMP*` to Gadi

```
rsync -aPL --append-verify --remove-source-files /data/cephfs/punim0010/data/Transfer/raijin/TIMESTAMP* yourUserName@gadi-dm.nci.org.au:/g/data3/gx8/projects/LASTNAME_PROJECT
```

Then resume with step 4 above. 

