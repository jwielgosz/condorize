#!/bin/bash

#==========================================================
# created: wielgosz  2017-05-22
#
#  example.bash
#
#  A single-threaded script we want to parallelize
#
#==========================================================

sess=1
sess=2
sub_list="101 102 103 104"
sess_list="1 2 3"

for sub in $sub_list ; do
	for sess in $sub_list ; do

		f=/mypath/data/mri/${sub}_${sess}/${sub}_${sess}.nii
		cmd="fmri_stuff –file $f"
		echo "Running first-level model..."
		echo "cmd is: $cmd"

	done
done
