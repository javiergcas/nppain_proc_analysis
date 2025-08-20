# Author: Javier Gonzalez-Castillo
# Date: 03/25/2025
#
# Prepare anatomical dataset for freesurfer
# This scripts assumes data is now organized according to BIDs

set -e

PRJ_DIR='/data/SFIMJGC/2024_Misha_Pain'
SUBJECTS_DIR=`echo ${PRJ_DIR}/freesurfer/`
ORIG_DATA_DIR=`echo ${PRJ_DIR}/orig_data`
PRCS_DATA_DIR=`echo ${PRJ_DIR}/prcs_data`
USERNAME=`whoami`
SWARM_DIR=`echo ${PRJ_DIR}/swarm.${USERNAME}/`
SWARM_PATH=`echo ${SWARM_DIR}/S00a_Freesurfer.SWARM.sh`
LOGS_DIR=`echo ${PRJ_DIR}/logs.${USERNAME}/S00a_Freesurfer.logs`
subjects=(sub-JACSTE)
sessions=(ses-1 ses-2)
echo "++ Subjects          : ${subjects[@]}"
echo "++ Project Folder    : ${PRJ_DIR}"
echo "++ Orig Data Folder  : ${PRJ_DIR}"
echo "++ Swarm Folder      : ${SWARM_PATH}"
echo "++ Logs Folder       : ${LOGS_DIR}"
echo "++ Freesurfer Folder : ${SUBJECTS_DIR}"
echo "++ Number of subjects: ${num_subjects}"

# Create log directory if needed
# ------------------------------
if [ ! -d ${SWARM_DIR} ]; then
   echo "++ INFO: Creating Swarm Folder in ${SWARM_DIR}"
   mkdir ${SWARM_DIR}
fi

# Create log directory if needed
# ------------------------------
if [ ! -d ${LOGS_DIR} ]; then
   echo "++ INFO: Creating Logs Folder in ${LOGS_DIR}"
   mkdir -p ${LOGS_DIR}
fi

# Create Fresurfer directory if needed
# ------------------------------------
if [ ! -d ${SUBJECTS_DIR} ]; then
   echo "++ INFO: Creating Subjects Folder in ${SUBJECTS_DIR}"
   mkdir ${SUBJECTS_DIR}
fi

# Write top comment in Swarm file 
# -------------------------------
echo "#Creation Date: `date`" > ${SWARM_PATH}
echo "#swarm -f ${SWARM_PATH} -g 24 -t 24 --time 12:00:00 --logdir ${LOGS_DIR} --module afni,freesurfer/7.4.1 --sbatch \"--export SUBJECTS_DIR=${SUBJECTS_DIR}\"" >> ${SWARM_PATH}
# Write one entry per subject in Swarm file
for sbj in ${subjects[@]}
do
    for ses in ${sessions[@]}
    do
        out_path=`echo ${PRCS_DATA_DIR}/${sbj}/${ses}/D00_PreFreesurfer`
        if [ ! -d ${out_path} ]; then
           echo "++ ${out_path} just created."
           mkdir -p ${out_path}
        fi
        echo "3dUnifize -overwrite -prefix ${out_path}/${sbj}_anat_unifize.nii.gz ${ORIG_DATA_DIR}/${sbj}/${ses}/anat/${sbj}_${ses}_acq-T1MPRAGEFS_rec-NDNORMMAGNITUDE_run-1_T1w.nii.gz; recon-all -all -subject ${sbj}_${ses} -i ${out_path}/${sbj}_anat_unifize.nii.gz -parallel -openmp 24" >> ${SWARM_PATH} 
    done
done
echo "++ INFO: Script finished correctly."
echo "++ Created Script --> ${SWARM_PATH}"
