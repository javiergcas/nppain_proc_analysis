set -e

PRJ_DIR='/data/SFIMJGC/Misha'
SUBJECTS_DIR=`echo ${PRJ_DIR}/freesurfer/`
ORIG_DATA_DIR=`echo ${PRJ_DIR}/orig_data`
PRCS_DATA_DIR=`echo ${PRJ_DIR}/prcs_data`
RESOURCES_DIR=`echo ${PRJ_DIR}/resources`
USERNAME=`whoami`
SWARM_DIR=`echo ${PRJ_DIR}/swarm.${USERNAME}/`
SWARM_PATH=`echo ${SWARM_DIR}/S00b_Freesurfer2AFNI.SWARM.sh`
LOGS_DIR=`echo ${PRJ_DIR}/logs.${USERNAME}/S00b_Freesurfer2AFNI.logs`
subjects=(`ls ${PRJ_DIR}/orig_data`)
num_subjects=`echo ${#subjects[@]}`
echo "++ Subjects          : ${subjects[@]}"
echo "++ Project Folder    : ${PRJ_DIR}"
echo "++ Orig Data Folder  : ${PRJ_DIR}"
echo "++ Swarm Folder      : ${SWARM_PATH}"
echo "++ Logs Folder       : ${LOGS_DIR}"
echo "++ Freesurfer Folder : ${SUBJECTS_DIR}"
echo "++ Number of subjects: ${num_subjects}"

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
echo "#Creation Date: `date`" > ${RESOURCES_DIR}/S00b_NotAvailable.txt
echo "#Creation Date: `date`" > ${RESOURCES_DIR}/S00b_WillTry.txt
echo "#Creation Date: `date`" > ${SWARM_PATH}
echo "#swarm -f ${SWARM_PATH} -g 24 -t 24 --partition quick,norm --logdir ${LOGS_DIR}  --module afni,freesurfer" >> ${SWARM_PATH}

# Write one entry per subject in CreateSwarm File
for sbj in ${subjects[@]}
do
   if [ ! -f ${SUBJECTS_DIR}/${sbj}/surf/lh.pial ]; then
           echo "$sbj" >> ${RESOURCES_DIR}/S00b_NotAvailable.txt
   else 
      echo "$sbj" >> ${RESOURCES_DIR}/S00b_WillTry.txt
      if [ ! -d ${sbj_path}/SUMA ]; then
           echo "@SUMA_Make_Spec_FS -sid ${sbj}  -NIFTI -fspath ${SUBJECTS_DIR}/${sbj}" >> ${SWARM_PATH} 
      fi
   fi
done

echo "++ INFO: Script finished correctly."
echo "++ Output script is ${SWARM_PATH}"
