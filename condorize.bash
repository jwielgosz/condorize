#!/bin/bash

#==================================================================
# created: wielgosz  2014-06-25
#
##
# Convert existing scripts to as parallel condor jobs.
# See more details below.
#
# Change log
#
#	0.1: Change variables "sub" and "sess" to
#		"cz_loop_1" and "cz_loop_2" to eliminate collisions
#
#	2017-05-22 added support for dagman
#
#
#==================================================================

if [ "$(basename $0)" == "condorize.bash" ] ; then

	helpfile="$(dirname $0)/dREADME.md"
	if [ -e "${helpfile}" ] ; then 
		cat "${helpfile}"
	else 
		cat <<-MSG
			condorize.bash: 

			Insert into existing scripts to parallelize them with HTCondor.
			Help file is missing: ${helpfile}
			For usage, see: https://github.com/wielgosz/condorize/
			
		MSG
	fi
fi

# ==========================================================

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

    	${cz_include_global}
	EOF


	for cz__x1 in $cz_loop_1 ; do
		for cz__x2 in $cz_loop_2 ; do

			cz__prefix="${cz__log_id}_${cz__x1}_${cz__x2}"

      if [ -n "$*" ] ; then
        args="condor_job ${cz__x1} ${cz__x2} $*"
      else
        args="condor_job ${cz__x1} ${cz__x2}"
      fi
			cat >> ${cz__submit_file}	<<- EOF

				Arguments="${args}"
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
	MSG

	exit



# ==========================================================


elif [ "$1" == "dag" ] ; then

	shift 					# get rid of the 'condor' arg, so the rest of $* can be
							# added to the condor_submit file

	cz__cmd=$(basename $0)  # get script name
	cz__log_id=${cz__cmd%%.*}   # remove everything after first "." for log ID

	cz__log_dir=log			# keep it simple for now
	mkdir -p ${cz__log_dir}

 	cz__job_dir=dag
 	rm -rf ${cz__job_dir}
 	mkdir -p ${cz__job_dir}

	cz__dag_file=${cz__job_dir}/${cz__log_id}.dag
	rm -f ${cz__dag_file}


	cz__job_file=${cz__dag_file}.singlejob
	cat > ${cz__job_file}	<<- EOF
		Universe=vanilla
		getenv=True
		Executable=${cz__cmd}
		Log=${cz__log_dir}/${cz__log_id}.log

		Arguments="\$(args)"
		Output=${cz__log_dir}/\$(jobname).out
		Error=${cz__log_dir}/\$(jobname).err
		Queue
	EOF


	for cz__x1 in $cz_loop_1 ; do
		for cz__x2 in $cz_loop_2 ; do

			cz__prefix="${cz__log_id}_${cz__x1}_${cz__x2}"

			#cz__job_file=${cz__job_dir}/${cz__prefix}.condor

			if [ -n "$*" ] ; then
				cz__args="condor_job ${cz__x1} ${cz__x2} $*"
			else
				cz__args="condor_job ${cz__x1} ${cz__x2}"
			fi
			
			cat >> ${cz__dag_file}	<<- EOF
				JOB ${cz__prefix} ${cz__job_file}
				VARS ${cz__prefix} jobname="\$(JOB)"  args="${cz__args}"
			EOF
			
			
			# Generates individual job files
			# cat > ${cz__job_file}	<<- EOF
# 				Universe=vanilla
# 				getenv=True
# 				Executable=${cz__cmd}
# 				Log=${cz__log_dir}/${cz__log_id}.log
# 
# 				Arguments="\$(args)"
# 				Output=${cz__log_dir}/${cz__prefix}.out
# 				Error=${cz__log_dir}/${cz__prefix}.err
# 				Queue
# 			EOF
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
		condor_submit_dag ${cz__dag_file}
	MSG

	exit



# ==========================================================


elif [ "$1" == "condor_job" ] ; then
	# We are running as a condor job

	# Set the subject & session for this job
	cz_arg_1=$2
	cz_arg_2=$3

	shift; shift; shift	# get rid of the condor_job args, so the rest of $* is
					    # available normally to the user's script
fi
