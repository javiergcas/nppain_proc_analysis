set -e

PRJ_DIR='/data/SFIMJGC/2024_Misha_Pain/'
SUBJECTS_DIR=`echo ${PRJ_DIR}/freesurfer/`
ORIG_DATA_DIR=`echo ${PRJ_DIR}/orig_data`
PRCS_DATA_DIR=`echo ${PRJ_DIR}/prcs_data`
RESOURCES_DIR=`echo ${PRJ_DIR}/resources`
SCRIPTS_DIR=`echo ${PRJ_DIR}/code/bash/`
USERNAME=`whoami`
SWARM_DIR=`echo ${PRJ_DIR}/swarm.${USERNAME}/`
SWARM_PATH=`echo ${SWARM_DIR}/S01_Preproc_Anat.SWARM.sh`
LOGS_DIR=`echo ${PRJ_DIR}/logs.${USERNAME}/S01_Preproc_Anat.logs`
subjects=(sub-JACSTE)
sessions=(ses-1 ses-2)

echo "++ Subjects          : ${subjects[@]}"
echo "++ Orig Data Folder  : ${ORIG_DATA_DIR}"
echo "++ Swarm Folder      : ${SWARM_PATH}"
echo "++ Logs Folder       : ${LOGS_DIR}"
echo "++ Freesurfer Folder : ${SUBJECTS_DIR}"

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
echo "#swarm -f ${SWARM_PATH} -g 32 -t 32 --time 08:00:00 --partition norm --module afni --logdir ${LOGS_DIR} --sbatch \"--export AFNI_COMPRESSOR=GZIP\"" > ${SWARM_PATH}

for sbj in ${subjects[@]}
do
   for ses in ${sessions[@]}
   do
    echo "export SBJ=${sbj} SES=${ses}; sh ${SCRIPTS_DIR}/S01_Preproc_Anat.sh" >> ${SWARM_PATH}
   done
done

echo "++ INFO: Script finished correctly."
