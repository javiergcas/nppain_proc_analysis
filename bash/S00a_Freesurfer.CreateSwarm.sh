set -e

PRJ_DIR='/data/SFIMJGC/Misha'
SUBJECTS_DIR=`echo ${PRJ_DIR}/freesurfer/`
ORIG_DATA_DIR=`echo ${PRJ_DIR}/orig_data`
PRCS_DATA_DIR=`echo ${PRJ_DIR}/prcs_data`
USERNAME=`whoami`
SWARM_DIR=`echo ${PRJ_DIR}/swarm.${USERNAME}/`
SWARM_PATH=`echo ${SWARM_DIR}/S00a_Freesurfer.SWARM.sh`
LOGS_DIR=`echo ${PRJ_DIR}/logs.${USERNAME}/S00a_Freesurfer.logs`
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
echo "#swarm -f ${SWARM_PATH} -g 24 -t 24 --time 12:00:00 --logdir ${LOGS_DIR} --module afni,freesurfer --sbatch \"--export SUBJECTS_DIR=${SUBJECTS_DIR}\"" >> ${SWARM_PATH}
# Write one entry per subject in Swarm file
for sbj in ${subjects[@]}
do
    out_path=`echo ${PRCS_DATA_DIR}/${sbj}/D00_PreFreesurfer`
    if [ ! -d ${out_path} ]; then
       echo "++ ${out_path} just created."
       mkdir -p ${out_path}
    fi
    #echo "3dUnifize -overwrite -prefix ${out_path}/${sbj}_anat_unifize.nii.gz ${ORIG_DATA_DIR}/${sbj}/${sbj}_anat.nii.gz; recon-all -all -subject ${sbj} -i ${ORIG_DATA_DIR}/${sbj}/${sbj}_anat.nii.gz" >> ${SWARM_PATH} 
    echo "3dUnifize -overwrite -prefix ${out_path}/${sbj}_anat_unifize.nii.gz ${ORIG_DATA_DIR}/${sbj}/${sbj}_anat.nii.gz; recon-all -all -subject ${sbj} -i ${out_path}/${sbj}_anat_unifize.nii.gz" >> ${SWARM_PATH} 
done
echo "++ INFO: Script finished correctly."
echo "++ Created Script --> ${SWARM_PATH}"
# NOTE: After a quick visual inspection of a few subjects, I think for this dataset we won't need to run 3dUnifize... so on a first pass, we will give freesurfer the original anat as input.
