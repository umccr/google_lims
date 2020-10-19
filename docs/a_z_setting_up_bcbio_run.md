# A-Z of running samples through the bcbio workflow

## 1. Create config files for the samples to be run

We are using two standard approaches to set up bcbio on Gadi:

* If this is for single patients, follow the [bcbioSetup_Single Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_Single.Rmd)
* If this is for WTS, follow the [bcbioSetup_WTS_Single Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_WTS_Single.Rmd)

For batch runs (e.g., research cohorts) there is also a generic [bcbio Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup.Rmd) which likely needs revisions at this point as it has not been used for a while. We also have an experimental [bcbio UMI Rmd](https://github.com/umccr/google_lims/blob/master/analysis/bcbioSetup_Single_UMI.Rmd) which is not meant for production use until we have standardized how UMI FASTQs are generated on NovaStore or IAP. 

Each of these workflows should result in three files: `TIMESTAMP_PROJECT.csv`, `TIMESTAMP_PROJECT.sh` file and a `project_name.txt` per subject folder.

## 2. Running the samples

### 2a. Using Spartan

**Note:** Spartan use has not been tested for a while. Limit to Gadi where possible.

If this is for **testing**, follow these guidelines to run the samples on **Spartan**. Note that the versions of bcbio and umccrise may be out of date on Spartan and subsequently superseded (check with `umccrise --version` and `bcbio_nextgen.py -v`).

```
$ scp -r TIMESTAMP_PROJECT* yourUserName@spartan.hpc.unimelb.edu.au:/data/cephfs/punim0010/projects/PROJECTDIR
$ sh TIMESTAMP_PROJECT_files.txt
$ cp /data/cephfs/punim0010/projects/std_workflow/merge.sh .  
$ vi merge.sh
$ sbatch merge.sh  
$ mv *-merged.csv ..; cd ..  
$ export PATH=/data/projects/punim0010/local/stable/bin:$PATH  
$ bcbio_nextgen.py -w template ../../std_workflow/std_workflow_cancer.yaml 2019-05-15T0319_Avner_WGS-merged.csv data/merged/*.gz  
$ cp ../../std_workflow/run.sh 2019-05-15T0319_Avner_WGS-merged/work; cd 2019-05-15T0319_Avner_WGS-merged/work  
$ vi run.sh  
$ sbatch run.sh  
$ less +F log/bcbio-nextgen-debug.log  
$ export PATH=/data/projects/punim0010/local/stable/bin:$PATH  
$ sbatch run.sh 
```

Point `umccrise` at the `final` directory: 

``` 
$ source /data/cephfs/punim0010/extras/umccrise/load_umccrise.sh  
$ export AWS_PROFILE=umccr  
$ umccrise . -j 16 --cluster-auto  
```

### 2b Gadi

Copy the folders created to spartan and update group read permissions.

```
$ scp -r TIMESTAMP_PROJECT/ yourUserName@spartan.hpc.unimelb.edu.au:/data/cephfs/punim0010/data/Transfer/raijin/
$ chmod g+w -R TIMESTAMP_PROJECT/
```

(Note it may be preferable to upload the folders into a new directory created within that location, if multiple users are using the directory simultaneously).

Log into Spartan, change to `umccr` user and activate aws conda environment:

```
$ sudo -i -u umccr
$ cd /data/cephfs/punim0010/data/Transfer/raijin/
$ conda activate aws
$ find /data/cephfs/punim0010/data/Transfer/raijin/ -name *files.sh* -execdir sh {} \;
```

Copy `TIMESTAMP_PROJECT/` to Gadi

```
$ rsync -aPL --append-verify --remove-source-files /data/cephfs/punim0010/data/Transfer/raijin/TIMESTAMP_PROJECT/ yourUserName@gadi-dm.nci.org.au:/g/data3/gx8/projects/TIMESTAMP_PROJECT
```

**Log into Gadi.**

Change into the new project directory created in the last step and copy over the relevant configuration file:

* for WGS `cp /g/data3/gx8/projects/std_workflow/scripts/config_bcbio.sh .`
* for WTS `cp /g/data3/gx8/projects/std_workflow/scripts/config_bcbio_wts.sh .`

If a WGS run includes **FFPE* samples it's usually best to move these to a separate project directory and use `config_bcbio_ffpe.sh` to configure these. This results in a reduced workflow set that ensures FFPE samples do not stall and cause delays. 

The `scripts` folder has additional drivers that can be used as needed, e.g., for exome or UMI runs. Replace the `PROJECTNAME` placeholder in the copied config script with the current project, then run it.

`sh config_bcbio.sh` or for WTS samples `sh config_bcbio_wts.sh`

This will set up the folder structure, merge input files (in the case of top-ups) and create run scripts which can be submitted with:

```
$ find ./2020* -name run.sh -and -not -path "*/data/*" -execdir qsub {} \;
```

The output can be monitored with:

```
$ watch -d -n 300 'find 2020*/ -maxdepth 4 -name bcbio-nextgen-debug.log -path "*/log/*" -and -not -path "*/data/*" -and -not -path "*/bcbiotx/*" 2>/dev/null | xargs tail -n 2'
```

## Organise results & upload to S3

After the runs finish successfully (a few hours for WTS, about 24-30h for WGS) data can be moved to AWS S3. Start by organizing results into the required folder structure by copying a helper script into the project directory:

```
$ cp /g/data3/gx8/projects/std_workflow/scripts/organize_s3.sh .
```

Again, adjust `PROJECT` in the first line of the script and run it; results should end up in an `s3` directory. Now data can be moved to S3. Start an interactive job (`qsub -I -P gx8 -q copyq -l walltime=12:00:00,ncpus=1,wd,mem=32G,jobfs=100GB`) and authenticate (`aws sso login --profile prod`). Add another helper script to the project folder:

* for WGS `cp /g/data3/gx8/projects/std_workflow/scripts/upload_s3.sh .`
* for WTS `cp /g/data3/gx8/projects/std_workflow/scripts/upload_s3_wts.sh .`


As per usual change the `PROJECT` name in the first script line, then run the script. It should iterate over project folders and samples in S3, upload them to AWS, then kick off `umccrise` in the case of WGS samples. The `#biobots` channel on Slack tracks the `umccrise` progress. 

After all of this completes successfully there's some housekeeping to do:

* Update the S3 `Results` locations in the Google LIMs.
* Wipe the project folders from Gadi
* Let Wing-Yee know that the run completed (e.g., in Slack's `#medical-genomics` channel)



