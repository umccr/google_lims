# Hard-coded project directory for now; don't want this to go off the rails
for DIRECTORY in /g/data/gx8/projects/PROJECT/2019*/ ;
do
  BATCH=$(basename $DIRECTORY)
  CLEANBATCH=${BATCH//./_}
  RUNDIR="$DIRECTORY"$CLEANBATCH-merged

  # Test if umccrise was started
  if [ -d $RUNDIR/umccrised ]; then
    echo $RUNDIR
    # Test if umccrise _finished_
    if [ -f $RUNDIR/umccrised/all.done ]; then
      # This means we're ready to sync the data to Spartan | S3
      # Organize by patient identifier
      PATIENT=$(echo $BATCH | cut -d '_' -f 4)

      # Add a timestamp
      TIMESTAMP=$(date +%Y-%m-%d)
      mkdir -p sync/$TIMESTAMP/$PATIENT

      # Config, final directory and umccrise results only
      # Leave a copy of the config behind in case of reruns
      cp -al $RUNDIR/umccrised sync/$TIMESTAMP/$PATIENT/
      cp -al $RUNDIR/config sync/$TIMESTAMP/$PATIENT/
      cp -al $RUNDIR/final sync/$TIMESTAMP/$PATIENT/

      # Extra copy to make sync to desktops easier: just the reports
      mkdir -p reports/$PATIENT
      cp -al $PWD/sync/$TIMESTAMP/$PATIENT/umccrised reports/$PATIENT/ # was ln -sn

      echo "  Ready for sync"
    else
      echo "  Still running"
    fi
  fi
done