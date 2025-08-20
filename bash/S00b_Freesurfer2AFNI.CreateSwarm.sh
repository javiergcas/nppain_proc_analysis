set -e

PRJ_DIR='/data/Brain_2025/pain_study_01/'
SUBJECTS_DIR=`echo ${PRJ_DIR}/freesurfer/`
ORIG_DATA_DIR=`echo ${PRJ_DIR}/orig_data`
PRCS_DATA_DIR=`echo ${PRJ_DIR}/prcs_data`
RESOURCES_DIR=`echo ${PRJ_DIR}/resources`
USERNAME=`whoami`
SWARM_DIR=`echo ${PRJ_DIR}/swarm.${USERNAME}/`
SWARM_PATH=`echo ${SWARM_DIR}/S00b_Freesurfer2AFNI.SWARM.sh`
LOGS_DIR=`echo ${PRJ_DIR}/logs.${USERNAME}/S00b_Freesurfer2AFNI.logs`
subjects=(sub-JACSTE)
sessions=(ses-1 ses-2)
echo "++ Subjects          : ${subjects[@]}"
echo "++ Project Folder    : ${PRJ_DIR}"
echo "++ Orig Data Folder  : ${PRJ_DIR}"
echo "++ Swarm Folder      : ${SWARM_PATH}"
echo "++ Logs Folder       : ${LOGS_DIR}"
echo "++ Freesurfer Folder : ${SUBJECTS_DIR}"

# Create log directory if needed
if [ ! -d ${LOGS_DIR} ]; then
   mkdir -p ${LOGS_DIR}
   echo "++ INFO: Creating Logs Folder ${LOGS_DIR}"
fi

if [ ! -d ${RESOURCES_DIR} ]; then
   mkdir -p ${RESOURCES_DIR}
   echo "++ INFO: Creating Logs Folder ${RESOURCES_DIR}"
fi

# Write top comment in CreateSwarm File
echo "#Creation Date: `date`" > ${SWARM_PATH}
echo "#swarm -f ${SWARM_PATH} -g 24 -t 24 --partition quick,norm --logdir ${LOGS_DIR}  --module afni,freesurfer/7.4.1" >> ${SWARM_PATH}

# Write one entry per subject in CreateSwarm File
for sbj in ${subjects[@]}
do
   for ses in ${sessions[@]}
   do
    echo "@SUMA_Make_Spec_FS -sid ${sbj}_${ses}  -NIFTI -fspath ${SUBJECTS_DIR}/${sbj}_${ses}" >> ${SWARM_PATH} 
   done
done

echo "++ INFO: Script finished correctly."
echo "++ Output script is ${SWARM_PATH}"
