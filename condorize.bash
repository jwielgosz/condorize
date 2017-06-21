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


	if [ -z "${cz_loop_1}" ] ; then 
		echo "cz_loop_1 not set; defaulting to single iteration"
	 	cz_loop_1=1
	fi

	if [ -z "${cz_loop_2}" ] ; then 
		echo "cz_loop_2 not set; defaulting to single iteration"
	 	cz_loop_2=1
	fi

	cz__n1=$( echo ${cz_loop_1} | wc -w )
	cz__n2=$( echo ${cz_loop_2} | wc -w )
	cat <<-EOF
		Condorizing... [${cz__n1}]x[${cz__n2}]

	EOF
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
				Output=${cz__log_dir}/${cz__prefix}.out.log
				Error=${cz__log_dir}/${cz__prefix}.err.log
        Queue
			EOF
		done
	done

	if ls ${cz__log_dir}/${cz__log_id}.* &> /dev/null; then
		cz__old_log_dir=${cz__log_dir}/old.${cz__log_id}.$(date +%F.%H-%M-%S)
		mkdir ${cz__old_log_dir}
		mv ${cz__log_dir}/${cz__log_id}.* ${cz__old_log_dir}/
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
 	rm -f ${cz__job_dir}/${cz__log_id}.dag*
 	mkdir -p ${cz__job_dir}

	cz__dag_file=${cz__job_dir}/${cz__log_id}.dag
	rm -f ${cz__dag_file}


	cz__job_file=${cz__dag_file}.singlejob

	if [ -z "${cz_loop_1}" ] ; then 
		echo "cz_loop_1 not set; defaulting to single iteration"
	 	cz_loop_1=1
	fi

	if [ -z "${cz_loop_2}" ] ; then 
		echo "cz_loop_2 not set; defaulting to single iteration"
	 	cz_loop_1=2
	fi
	
	cz__n1=$( echo ${cz_loop_1} | wc -w )
	cz__n2=$( echo ${cz_loop_2} | wc -w )
	cat <<-EOF
	
		Condorizing... [${cz__n1}]x[${cz__n2}]

	EOF
	
	if [ -n "${cz_post_1}" ] || [ -n "${cz_post_2}" ] ; then 
		cat <<-EOF
			Post-processing:
			  cz_post_1=${cz_post_1}
			  cz_post_1_args="${cz_post_1_args}"
			  
			  cz_post_2=${cz_post_2}
			  cz_post_2_args="${cz_post_2_args}"
			  
		EOF
	fi
	
	if [ -n "${cz_include_dag}" ] || [ -n "${cz_include_job}" ] ; then 
		cat <<-EOF
			----------------------------------------------------------
			Custom includes
			cz_include_dag:
			${cz_include_dag}
	
			cz_include_job:
			${cz_include_job}
			----------------------------------------------------------
			
		EOF
	fi
	
	
	cat > ${cz__job_file}	<<- EOF
		Universe=vanilla
		getenv=True
		Executable=\$(cmd)
		Log=${cz__log_dir}/${cz__log_id}.log

		# ----------------------------------------------------------
		# Custom includes:
		${cz_include_job}
		# ----------------------------------------------------------
		
		Arguments="\$(args)"
		Output=${cz__log_dir}/\$(jobname).out.log
		Error=${cz__log_dir}/\$(jobname).err.log
		Queue
		
	EOF



	cat >> ${cz__dag_file}	<<- EOF
		# ==========================================================
		# Job: ${cz__log_id}
		# Generated: $( date )
		# Source: ${cz__cmd}
		# ==========================================================
		
		# ----------------------------------------------------------
		# Custom includes:
		${cz_include_dag}
		# ----------------------------------------------------------
		
	EOF


	if [ -n "${cz_post_1}" ] ; then
		cz__post1_job=${cz__log_id}_post
		cat >> ${cz__dag_file}	<<- EOF
			# Post-processing for outer loop (cz_loop_1)
			JOB ${cz__post1_job} ${cz__job_file}
			VARS ${cz__post1_job} jobname="\$(JOB)" cmd="${cz_post_1}" args="${cz_post_1_args}"
		EOF
	fi


	for cz__x1 in $cz_loop_1 ; do

		cat >> ${cz__dag_file}	<<- EOF
			# ----------------------------------------------------------
			# cz_loop_1 = $cz__x1
			# ----------------------------------------------------------
			 
		EOF


		if [ -n "${cz_post_2}" ] ; then
			cz__post2_job=${cz__log_id}_post_${cz__x1}
			cat >> ${cz__dag_file}	<<- EOF
				# Post-processing for inner loop (cz_loop_2)
				JOB ${cz__post2_job} ${cz__job_file}
				VARS ${cz__post2_job} jobname="\$(JOB)" cmd="${cz_post_2}" args="${cz_post_2_args} ${cz__x1}"
			EOF

			if [ -n "${cz_post_1}" ] ; then
				cat >> ${cz__dag_file}	<<- EOF
					PARENT ${cz__post2_job} CHILD ${cz__post1_job}
				EOF
			fi

			echo >> ${cz__dag_file}

		fi


		for cz__x2 in $cz_loop_2 ; do

			cz__job="${cz__log_id}_${cz__x1}_${cz__x2}"

			#cz__job_file=${cz__job_dir}/${cz__prefix}.condor

			if [ -n "$*" ] ; then
				cz__args="condor_job ${cz__x1} ${cz__x2} $*"
			else
				cz__args="condor_job ${cz__x1} ${cz__x2}"
			fi
			
			cat >> ${cz__dag_file}	<<- EOF
				JOB ${cz__job} ${cz__job_file}
				VARS ${cz__job} jobname="\$(JOB)" cmd="${cz__cmd}" args="${cz__args}"
				CATEGORY ${cz__job} ${cz__log_id}
			EOF

			if [ -n "${cz_post_2}" ] ; then
				cat >> ${cz__dag_file}	<<- EOF
					PARENT ${cz__job} CHILD ${cz__post2_job}
				EOF
			elif [ -n "${cz_post_1}" ] ; then
				cat >> ${cz__dag_file}	<<- EOF
					PARENT ${cz__job} CHILD ${cz__post1_job}
				EOF
			fi
			
			echo >> ${cz__dag_file}
	
		done

		
	done

	if ls ${cz__log_dir}/${cz__log_id}.* &> /dev/null; then
		cz__old_log_dir=${cz__log_dir}/old.${cz__log_id}.$(date +%F.%H-%M-%S)
		mkdir ${cz__old_log_dir}
		mv ${cz__log_dir}/${cz__log_id}.* ${cz__old_log_dir}/
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
