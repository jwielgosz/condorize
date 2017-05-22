#!/bin/bash

#==========================================================
# created: wielgosz  2017-05-22
#
#  Condorized version of example.original.bash
#
#==========================================================


# --------------------------------------------------------------
# condorize setup

cz_arg_1=101	# Default value
cz_arg_2=1	# Default value

cz_loop_1="101 102 103 104"
cz_loop_2="1 2"
source ./condorize.sh # change this to path where condorize is located

# --------------------------------------------------------------


sub=${cz_arg_1}	# subject ID
sess=${cz_arg_2} # session number

f=/mypath/data/mri/${sub}_${sess}/${sub}_${sess}.nii
cmd="fmri_stuff –file $f"
echo "Running first-level model..."
echo "cmd is: $cmd"

