set -e

PRJ_DIR='/data/SFIMJGC/Misha'
SUBJECTS_DIR=`echo ${PRJ_DIR}/freesurfer/`
ORIG_DATA_DIR=`echo ${PRJ_DIR}/orig_data`
PRCS_DATA_DIR=`echo ${PRJ_DIR}/prcs_data`
RESOURCES_DIR=`echo ${PRJ_DIR}/resources`
SCRIPTS_DIR=`echo ${PRJ_DIR}/code/bash/`
USERNAME=`whoami`
SWARM_DIR=`echo ${PRJ_DIR}/swarm.${USERNAME}/`
SWARM_PATH=`echo ${SWARM_DIR}/S01_Preproc_Anat.SWARM.sh`
LOGS_DIR=`echo ${PRJ_DIR}/logs.${USERNAME}/S01_Preproc_Anat.logs`
subjects=(`ls ${PRJ_DIR}/orig_data`)
num_subjects=`echo ${#subjects[@]}`

echo "++ Subjects          : ${subjects[@]}"
echo "++ Orig Data Folder  : ${ORIG_DATA_DIR}"
echo "++ Swarm Folder      : ${SWARM_PATH}"
echo "++ Logs Folder       : ${LOGS_DIR}"
echo "++ Freesurfer Folder : ${SUBJECTS_DIR}"
echo "++ Number of subjects: ${num_subjects}"


# Create log directory if needed
# ------------------------------
if [ ! -d ${LOGS_DIR} ]; then
   mkdir -p ${LOGS_DIR}
fi

# Write top comment in Swarm file 
# -------------------------------
echo "#Creation Date: `date`" > ${RESOURCES_DIR}/S01_NotAvailable.txt
echo "#Creation Date: `date`" > ${RESOURCES_DIR}/S01_WillTry.txt
echo "#Creation Date: `date`" > ${SWARM_PATH}
echo "#swarm -f ${SWARM_PATH} -g 32 -t 32 --partition quick,norm --module afni --logdir ${LOGS_DIR} --sbatch \"--export AFNI_COMPRESSOR=GZIP\"" > ${SWARM_PATH}

for sbj_path in ${subjects[@]}
do
   sbj=`basename ${sbj_path}`
   if [ ! -d ${SUBJECTS_DIR}/${sbj}/SUMA ]; then 
      echo "${sbj}" >> ${RESOURCES_DIR}/S01_NotAvailable.txt
   else
      if [ -z "$(ls -A ${SUBJECTS_DIR}/${sbj}/SUMA)" ]; then
        echo "${sbj}" >> ${RESOURCES_DIR}/S01_NotAvailable.txt
      else
        echo "${sbj}" >> ${RESOURCES_DIR}/S01_WillTry.txt
        echo "export SBJ=${sbj}; sh ${SCRIPTS_DIR}/S01_Preproc_Anat.sh" >> ${SWARM_PATH}
      fi
   fi
done

echo "++ INFO: Script finished correctly."
