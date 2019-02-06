# Hard-coded project directory for now; don't want this to go off the rails
for DIRECTORY in /g/data/gx8/projects/PROJECT/2019*/ ;
do
  BATCH=$(basename $DIRECTORY)
  CLEANBATCH=${BATCH//./_}
  RUNDIR="$DIRECTORY"$CLEANBATCH-merged

  # Test if umccrise was started
  if [ -d $RUNDIR/umccrised-cromwell ]; then
    echo $RUNDIR
    # Test if umccrise _finished_
    if [ -f $RUNDIR/umccrised-cromwell/all.done ]; then
      # This means we're ready to sync the data to Spartan | S3
      # Organize by patient identifier
      PATIENT=$(echo $BATCH | cut -d '_' -f 4)

      # Add a timestamp
      TIMESTAMP=$(date +%Y-%m-%d)
      mkdir -p sync-cromwell/$TIMESTAMP/$PATIENT

      # Config, final directory and umccrise results only
      ln -sn $RUNDIR/umccrised-cromwell sync-cromwell/$TIMESTAMP/$PATIENT/
      ln -sn $RUNDIR/config sync-cromwell/$TIMESTAMP/$PATIENT/
      ln -sn $RUNDIR/final-cromwell sync-cromwell/$TIMESTAMP/$PATIENT/

      # Extra copy to make sync to desktops easier: just the reports
      mkdir -p reports-cromwell/$PATIENT
      ln -sn $RUNDIR/umccrised-cromwell reports-cromwell/$PATIENT/

      echo "  Ready for sync"
    else
      echo "  Still running"
    fi
  fi
done