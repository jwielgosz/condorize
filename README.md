condorize.bash

Use to convert an existing script to run subjects/sessions as
parallel condor jobs.

Your script must be set up to run a single subject/session at a time,
using the variables $cz_loop_1 and $cz_loop_2. 

To convert it to a parallelized condor script, add the three lines
shown below.

Invoking condorize.bash directly does nothing except display this help message.

Example:

1) Add the lines marked with '>' to your script, e.g. myscript.sh:

		...
		# allow testing without use of condor
		cz_arg_1=$1
		cz_arg_2=$2

	>	 cz_loop_1="101 102 103"	# give condorize.bash a subject list
	>	 cz_loop_2="1 2"			# give condorize.bash a session list
	>	 source <path_to_condorize>/condorize.bash		# run the condorize.bash code

		# existing code, to run your actual analysis
		# e.g...
		studyID=$cz_arg_1
		session=$cz_arg_2

		do_something -a -b -c $studyID $session
		do_something_else -x $studyID -y $session
		...

IMPORTANT: condorize.bash directly manipulates the command line arguments ($1, $2, $3).
Do not modify these arguments above the line that invokes condorize.bash in your
script.

2) Generate a condor batch job as follows:

	[bucky]$ myscript.sh condor
	To submit: condor_submit myscript.condor

or

	[bucky]$ myscript.sh dag
	To submit: condor_submit_dag dag/myscript.dag

Note: You can also run all of your jobs with a particular set of arguments as follows:

	[bucky]$ myscript.sh condor arg1 arg2 arg3 ...

This will result in the arguments being passed to each run of your script. They will
be available as $1, $2, $3, etc. at any point *after* the line where condorize.bash is
invoked.

3) Submit the batch job. Your script will be invoked for each subject/session pair,
with the appropriate values placed in $sub and $sess for each job. The command
will return as soon as your jobs have been placed in the queue.

	[bucky]$ condor_submit myscript.condor
	Submitting job(s)..
	6 job(s) submitted to cluster 18846

or


	[bucky]$ condor_submit_dag dag/myscript.dag

	-----------------------------------------------------------------------
	File for submitting this DAG to HTCondor		   : dag/myscript.dag.condor.sub
	Log of DAGMan debugging messages				 : dag/myscript.dag.dagman.out
	Log of HTCondor library output					   : dag/myscript.dag.lib.out
	Log of HTCondor library error messages			   : dag/myscript.dag.lib.err
	Log of the life of condor_dagman itself			 : dag/myscript.dag.dagman.log

	Submitting job(s).
	1 job(s) submitted to cluster 12345678.
	-----------------------------------------------------------------------


4) Output from your condor run will appear in the log/ folder. Logs from previous
runs will be moved out of the way, into a time-stamped subfolder, each time you re-run
 "myscript.sh condor".

5) To use your script without invoking condor, just assign the values you
want for $cz_arg_1 and $cz_arg_2 above the call to condorize. Unless you
invoke your script with the argument "condor" or "condor_job",
condorize.bash has no effect, and your script will run exactly as before;
all command line arguments ($1, $2, $3, etc.) will be unaffected.

IMPORTANT: Only modify $cz_arg_1 and $cz_arg_2 *before* the line that invokes condorize.bash.
If your script modifies them afterward, condorize.bash will not work correctly.

See http://research.cs.wisc.edu/htcondor/manual/ for more
