# Hard-coded project directory for now; don't want this to go off the rails
for DIRECTORY in /g/data/gx8/projects/PROJECT/2019*/ ;
do
  BATCH=$(basename $DIRECTORY)
  CLEANBATCH=${BATCH//./_}
  RUNDIR="$DIRECTORY"$CLEANBATCH-merged/work-cromwell/cromwell_work
  TARGETDIR="$DIRECTORY"$CLEANBATCH-merged/final-cromwell
  UMCCRDIR="$DIRECTORY"$CLEANBATCH-merged

  # Test if the final directory is present and not empty
  if [ ! -e $RUNDIR ]; then
    echo "$BATCH has not been run yet" 
  elif [ ! -e $RUNDIR/final ]; then
    echo "$BATCH has not finished yet (or final directory has been moved)"
  elif [ -n "$(ls -A $RUNDIR/final)" ]; then
    echo "$BATCH ready for processing"

    # Move the final folder to the sample level and rename
    mv $RUNDIR/final $TARGETDIR
  else
    echo "$BATCH still running"
  fi

  # Test if final directory is in new place; check if umccr is done
  if [ -e $TARGETDIR ]; then
    if [ -f $TARGETDIR/umccrised-cromwell/all.done ]; then
      echo "  Already done"
    else
      echo "  Submit"
      cp -v /g/data/gx8/projects/std_workflow/run_umccrise_cromwell.sh $UMCCRDIR
      cd $UMCCRDIR
      qsub run_umccrise_cromwell.sh
    fi
  fi
done
