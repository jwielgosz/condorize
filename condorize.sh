#!/bin/bash

#==================================================================
# created: wielgosz  2014-06-25
# 
# Convert existing scripts to as parallel condor jobs. 
# See more details below. 
#
#==================================================================

if [ "$(basename $0)" == "condorize.sh" ] ; then
cat <<'HELP'
    condorize.sh
    
    Use to convert an existing script to run subjects/sessions as 
    parallel condor jobs. 
    
    Your script must be set up to run a single subject/session at a time,
    using the variables $sub and $sess.
    
    To convert it to a parallelized condor script, add the three lines 
    shown below. 
    
    Invoking condorize.sh directly does nothing except display this help message.
    
    Example: 
    
    1) Add the lines marked with '>' to your script, e.g. myscript.sh:

        ...
        # existing code, to set up for non-condor runs
        sub=$1    
        sess=$2    

    >    condorize_subjects="101 102 103"    # give condorize.sh a subject list
    >    condorize_sessions="1 2"            # give condorize.sh a session list
    >    source condorize.sh                 # run the condorize.sh code
    
        # existing code, to run your actual analysis 
        do_something -a -b -c $sub $sess 
        do_something_else -x $sub -y $sess 
        ...

	IMPORTANT: condorize.sh uses the first three command line arguments ($1, $2, $3). 
	Do not modify these arguments above the line that invokes condorize.sh in your 
	script. 

    2) Generate a condor batch job as follows:

        [bucky]$ myscript.sh condor
        To submit: condor_submit myscript.condor
        To monitor: condor_wait log/myscript.log

	Note: You can also run all of your jobs with a particular set of arguments as follows:

        [bucky]$ myscript.sh condor arg1 arg2 arg3 ...

	This will result in the arguments being passed to each run of your script. They will
	be available as $1, $2, $3, etc. at any point *after* the line where condorize.sh is 
	invoked.  

    3) Run condor_submit. Your script will be invoked for each subject/session pair, 
    with the appropriate values placed in $sub and $sess for each job. The command
    will return as soon as your jobs have been placed in the queue. 

        [bucky]$ condor_submit myscript.condor
        Submitting job(s)..
        6 job(s) submitted to cluster 18846
        [bucky]$ 

    If you want to be notified in your terminal when your jobs complete, run the following 
    instead:
        
        [bucky]$ condor_submit myscript.condor; condor_wait log/myscript.log 

    You can get even fancier and run a notification command (e.g., send yourself an 
    email) like so:

        [bucky]$ (condor_submit myscript.condor; condor_wait log/myscript.log ; \ 
            echo 'Coffee break over!' | mail -s 'Condor run complete' bucky@wisc.edu ) &

    4) Output from your condor run will appear in the log/ folder. Logs from previous 
    runs will be moved out of the way, into a time-stamped subfolder, each time you re-run
     "myscript.sh condor". 

    5) To use your script without invoking condor, just assign the values you want for 
    $sub and $sess in myscript.sh. Unless you invoke your script with the argument 
    "condor" or "condor_job", condorize.sh has no effect, and your script will run 
    exactly as before; all command line arguments ($1, $2, $3, etc.) will be 
    unaffected. 
    
    IMPORTANT: Only set $sub and $sess *before* the line that invokes condorize.sh. 
    If $sub and $sess are altered afterward, condorize.sh will not work correctly. 

HELP
fi

if [ "$1" == "condor" ] ; then
	shift 					# get rid of the 'condor' arg, so the rest of $* can be
							# added to the condor_submit file

	cz__cmd=$(basename $0)  # get script name
	cz__log_id=${cz__cmd%%.*}   # remove everything after first "." for log ID

	cz__log_dir=log			# keep it simple for now
	mkdir -p ${cz__log_dir}

	cz__submit_file=${cz__log_id}.condor
	
	cat > ${cz__submit_file} <<- EOF
		Universe=vanilla
		getenv=True
		Executable=${cz__cmd}
		Log=${cz__log_dir}/${cz__log_id}.log
	EOF


	for cz__sess in $condorize_sessions ; do
		for cz__sub in $condorize_subjects ; do

			cz__prefix="${cz__log_id}_${cz__sub}_${cz__sess}"

			cat >> ${cz__submit_file}	<<- EOF
		
				Arguments="condor_job ${cz__sub} ${cz__sess} $*"
				Output=${cz__log_dir}/${cz__prefix}.out
				Error=${cz__log_dir}/${cz__prefix}.err
				Queue
			EOF
		done
	done

	if ls ${cz__log_dir}/${cz__log_id}* &> /dev/null; then
		cz__old_log_dir=${cz__log_dir}/old.${cz__log_id}.$(date +%F.%T)
		mkdir ${cz__old_log_dir}
		mv ${cz__log_dir}/${cz__log_id}* ${cz__old_log_dir}/
		echo "Old logs moved to ${cz__old_log_dir}"
	fi

	cat <<- MSG
		To submit: 
		condor_submit ${cz__submit_file}
		To monitor: 
		condor_submit ${cz__submit_file}; condor_wait ${cz__log_dir}/${cz__log_id}.log
	MSG
	
	exit
	
elif [ "$1" == "condor_job" ] ; then
	# We are running as a condor job

	# Set the subject & session for this job
	sub=$2
	sess=$3
	
	shift; shift; shift	# get rid of the condor_job args, so the rest of $* is 
					    # available normally to the user's script
fi
	
