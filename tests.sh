#!/bin/bash

# Tests to make sure the FSL image works and we didn't
# delete any library/file that is needed.
#
# This is not exhaustive.

docker run --rm test_fsl '\
MNI_2mm=$FSLDIR/data/standard/MNI152_T1_2mm \
&& MNI_1mm=$FSLDIR/data/standard/MNI152_T1_1mm \
&& echo "testing fslmaths..." \
&& $FSLDIR/bin/fslmaths ${MNI_2mm} -add ${MNI_2mm}_brain /tmp/deleteme \
&& echo "testing bet..." \
&& $FSLDIR/bin/bet ${MNI_2mm} /tmp/deleteme \
&& echo "testing flirt..." \
&& $FSLDIR/bin/flirt -in ${MNI_2mm} -ref ${MNI_1mm} -out /tmp/deleteme'
