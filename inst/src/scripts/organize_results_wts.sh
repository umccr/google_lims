# Hard-coded project directory for now; don't want this to go off the rails
#
# Organises data according to
#
#   Project -> Type -> Timestamp
#
# in a `sync` folder ready to be archived on AWS in the relevant
# `project` folder.
#
# Also creates a convenience `reports` folder for Trello
for DIRECTORY in /g/data/gx8/projects/PROJECT/2019*/ ;
do
  BATCH=$(basename $DIRECTORY)
  CLEANBATCH=${BATCH//./_}
  RUNDIR="$DIRECTORY"

  # Test if run finished
  if [ -n "$(ls -A $RUNDIR/final)" ]; then
    echo "$BATCH ready for processing"

    # Organize by project
    PROJECT=$(echo $BATCH | cut -d '_' -f 2)
    TYPE=$(echo $BATCH | cut -d '_' -f 3)

    # Add a timestamp
    TIMESTAMP=$(date +%Y-%m-%d)
    mkdir -p sync/$PROJECT/$TYPE/$TIMESTAMP/

    # Config, final directory only
    # Leave a copy of the config behind in case of reruns
    cp -al $RUNDIR/config sync/$PROJECT/$TYPE/$TIMESTAMP/
    cp -al $RUNDIR/final sync/$PROJECT/$TYPE/$TIMESTAMP/

    # Extra copy to make sync to desktops easier: just the reports
    mkdir -p reports/$PROJECT
    find $PWD/sync/$PROJECT -name multiqc_report.html -exec ln {} reports/$PROJECT/ \;
#    cp -al $PWD/sync/$PROJECT/$TYPE/$TIMESTAMP/final/*merged/multiqc reports/$PROJECTS/

    echo "  Ready for sync"
  else
    echo "  Still running"
  fi
done