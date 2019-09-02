# Hard-coded project directory for now; don't want this to go off the rails
for DIRECTORY in /g/data/gx8/projects/PROJECT/2019*/ ;
do
  BATCH=$(basename $DIRECTORY)
  CLEANBATCH=${BATCH//./_}
  RUNDIR="$DIRECTORY"$CLEANBATCH-merged

  if [ -n "$(ls -A $RUNDIR/final)" ]; then
    # Run finished; trigger Arriba move and plot results
    for FOLDER in $RUNDIR/work/arriba/* ;
    do
      # Get sample ID
      SAMPLE=$(basename $FOLDER)

      # Make sure that Arriba sample id matches bcbio's folder
      if [ -n "$(ls -A $RUNDIR/final/$SAMPLE)" ]; then
        # Move Arriba data from work to final
        echo "Moving Arriba results for $SAMPLE"
        mkdir -p $RUNDIR/final/$SAMPLE/arriba
        cp -al $FOLDER/* $RUNDIR/final/$SAMPLE/arriba/

        # Kick off draw
	BAM=$RUNDIR/final/$SAMPLE/$SAMPLE-ready.bam
        FUSION=$RUNDIR/final/$SAMPLE/arriba/fusions.tsv
        PDF=$RUNDIR/final/$SAMPLE/arriba/fusions.pdf

        export PATH=/g/data3/gx8/local/development/bcbio/anaconda/bin:/g/data/gx8/local/development/bin:/opt/bin:/bin:/usr/bin:/opt/pbs/default/bin
        draw_fusions.R --fusions=$FUSION --alignments=$BAM  --output=$PDF --annotation=/g/data3/gx8/local/development/bcbio/genomes/Hsapiens/GRCh37/rnaseq/ref-transcripts.gtf --cytobands=/g/data/gx8/projects/Hofmann_WTSSingle_Arriba/arriba_v1.1.0/database/cytobands_hg19_hs37d5_GRCh37_2018-02-23.tsv --proteinDomains=/g/data/gx8/projects/Hofmann_WTSSingle_Arriba/arriba_v1.1.0/database/protein_domains_hg19_hs37d5_GRCh37_2018-03-06.gff3
        echo "--"
      else
        echo "Unknown sample $SAMPLE, skipping"
      fi
    done
  fi 
done