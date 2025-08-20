# Author: Javier Gonzalez-Castillo
# Date: 03/27/2025
#
# Description:
# Updated script to read BIDS like data and write in BIDS like formate
#
# NOTE:
# Echo times are hard coded. Check the values still apply.

set -e

module load afni

PRJDIR='/data/Brain_2025/pain_study_01/'   # Project directory: includes Scripts, Freesurfer and PrcsData folders

PRCSDATA_DIR=`echo ${PRJDIR}/prcs_data`
ORIGDATA_DIR=`echo ${PRJDIR}/orig_data`
SUBJECTS_DIR=`echo ${PRJDIR}/freesurfer/`
RESOURCES_DIR=`echo ${PRJDIR}/resources/`
SCRIPTS_DIR=`echo ${PRJDIR}/code/bash/`
USERNAME=`whoami`
SWARM_PATH=`echo ${PRJDIR}/swarm.${USERNAME}/S02_Preproc.SWARM.sh`
LOGS_DIR=`echo ${PRJDIR}/logs.${USERNAME}/S02_Preproc.logs`
subjects=(sub-JACSTE)
sessions=(ses-1 ses-2)
echo "++ Subjects: ${subjects[@]}"
echo "++ Orig Data Folder  : ${PRCSDATA_DIR}"
echo "++ Scripts Folder    : ${SCRIPTS_DIR}"
echo "++ Swarm Folder      : ${SWARM_PATH}"
echo "++ Logs Folder       : ${LOGS_DIR}"
echo "++ Freesurfer Folder : ${SUBJECTS_DIR}"

# Initialize Swarm File
# ---------------------
echo "#swarm -f ${SWARM_PATH} -g 32 -t 32 --time 08:00:00 --module afni --logdir ${LOGS_DIR} --sbatch \"--export AFNI_COMPRESSOR=GZIP\"" > ${SWARM_PATH}

# Create log directory if needed (for swarm files)
# ------------------------------------------------
if [ ! -d ${LOGS_DIR} ]; then 
   mkdir -p ${LOGS_DIR}
fi

# Create directory for all fMRI data processing files per subject if needed
# -------------------------------------------------------------------------
AFNI_PROC_SCRIPTS_DIR=`echo ${SCRIPTS_DIR}S02_Afni_Preproc/`
if [ ! -d ${AFNI_PROC_SCRIPTS_DIR} ]; then 
   mkdir ${AFNI_PROC_SCRIPTS_DIR}
fi

# Copy and process all fMRI data
# ------------------------------
echo "++ INFO: Entering loop (through subjects....)"
for SBJ in ${subjects[@]}
do
    for SES in ${sessions[@]}
    do
       ANAT_PROC_DIR=`echo ${PRCSDATA_DIR}/${SBJ}/${SES}/D01_Anatomical`
       OUT_DIR=`echo ${PRCSDATA_DIR}/${SBJ}/${SES}/D02_Preproc`
       afni_proc.py                                                                                                                                            \
          -subj_id ${SBJ}_${SES}                                                                                                                               \
          -uvar taskname Rest                                                                                                                                  \
          -uvar ses ${SES}                                                                                                                                     \
          -blocks despike tshift align tlrc volreg mask combine scale regress                                                                                  \
          -radial_correlate_blocks tcat volreg                                                                                                                 \
          -copy_anat ${ANAT_PROC_DIR}/anatSS.${SBJ}.nii.gz                                                                                                     \
          -anat_has_skull no                                                                                                                                   \
          -anat_follower anat_w_skull anat ${ANAT_PROC_DIR}/anatUAC.${SBJ}.nii.gz                                                                              \
          -anat_follower_ROI aaseg  anat ${SUBJECTS_DIR}/${SBJ}_${SES}/SUMA/aparc.a2009s+aseg.nii.gz                                                           \
          -anat_follower_ROI aeseg  epi  ${SUBJECTS_DIR}/${SBJ}_${SES}/SUMA/aparc.a2009s+aseg.nii.gz                                                           \
          -anat_follower_ROI FSvent epi  ${SUBJECTS_DIR}/${SBJ}_${SES}/SUMA/fs_ap_latvent.nii.gz                                                               \
          -anat_follower_ROI FSWe   epi  ${SUBJECTS_DIR}/${SBJ}_${SES}/SUMA/fs_ap_wm.nii.gz                                                                    \
          -anat_follower_ROI lhRib  epi  ${SUBJECTS_DIR}/${SBJ}_${SES}/SUMA/lh.ribbon.nii.gz                                                                   \
          -anat_follower_ROI rhRib  epi  ${SUBJECTS_DIR}/${SBJ}_${SES}/SUMA/rh.ribbon.nii.gz                                                                   \
          -anat_follower_erode FSvent FSWe                                                                                                                     \
          -tcat_remove_first_trs 0                                                                                                                             \
          -tshift_interp -wsinc9                                                                                                                               \
          -dsets_me_echo ${ORIGDATA_DIR}/${SBJ}/${SES}/func/${SBJ}_${SES}_task-Run?CMRREPITR2MB2ME3275iso_dir-AP_run-?_echo-1_part-mag_bold.nii.gz             \
          -dsets_me_echo ${ORIGDATA_DIR}/${SBJ}/${SES}/func/${SBJ}_${SES}_task-Run?CMRREPITR2MB2ME3275iso_dir-AP_run-?_echo-2_part-mag_bold.nii.gz             \
          -dsets_me_echo ${ORIGDATA_DIR}/${SBJ}/${SES}/func/${SBJ}_${SES}_task-Run?CMRREPITR2MB2ME3275iso_dir-AP_run-?_echo-3_part-mag_bold.nii.gz             \
          -echo_times 15.2 37.48 59.76                                                                                                                         \
          -blip_reverse_dset ${ORIGDATA_DIR}/${SBJ}/${SES}/func/${SBJ}_${SES}_task-RevBlipCMRREPITR2MB2ME3275iso_dir-LR_run-1_echo-2_part-mag_bold.nii.gz'[0]' \
          -blip_forward_dset ${ORIGDATA_DIR}/${SBJ}/${SES}/func/${SBJ}_${SES}_task-Run1CMRREPITR2MB2ME3275iso_dir-AP_run-1_echo-2_part-mag_bold.nii.gz'[0]'    \
          -reg_echo 2                                                                                                                                          \
          -combine_method m_tedana                                                                                                                             \
          -align_unifize_epi local                                                                                                                             \
          -combine_opts_tedana "--mask mask_group+tlrc.HEAD"                                                                                                   \
          -align_opts_aea -cost lpc+ZZ -giant_move -check_flip                                                                                                 \
          -tlrc_base MNI152_2009_template_SSW.nii.gz                                                                                                           \
          -tlrc_NL_warp                                                                                                                                        \
          -tlrc_NL_warped_dsets ${ANAT_PROC_DIR}/anatQQ.${SBJ}.nii.gz                                                                                          \
                                ${ANAT_PROC_DIR}/anatQQ.${SBJ}.aff12.1D                                                                                        \
                                ${ANAT_PROC_DIR}/anatQQ.${SBJ}_WARP.nii.gz                                                                                     \
          -volreg_align_to MIN_OUTLIER                                                                                                                         \
          -volreg_align_e2a                                                                                                                                    \
          -volreg_tlrc_warp                                                                                                                                    \
          -volreg_warp_dxyz 2.5                                                                                                                                \
          -volreg_warp_final_interp  wsinc5                                                                                                                    \
          -volreg_compute_tsnr       yes                                                                                                                       \
          -mask_epi_anat yes                                                                                                                                   \
          -regress_opts_3dD -jobs 32                                                                                                                           \
          -regress_motion_per_run                                                                                                                              \
          -regress_ROI_PC FSvent 3                                                                                                                             \
          -regress_ROI_PC_per_run FSvent                                                                                                                       \
          -regress_make_corr_vols aeseg FSvent                                                                                                                 \
          -regress_anaticor_fast                                                                                                                               \
          -regress_anaticor_label FSWe                                                                                                                         \
          -regress_censor_motion 0.2                                                                                                                           \
          -regress_censor_outliers 0.05                                                                                                                        \
          -regress_apply_mot_types demean deriv                                                                                                                \
          -regress_bandpass 0.01 0.1                                                                                                                           \
          -regress_polort 4                                                                                                                                    \
          -regress_run_clustsim no                                                                                                                             \
          -html_review_style pythonic                                                                                                                          \
          -out_dir ${OUT_DIR}                                                                                                                                  \
          -script ${AFNI_PROC_SCRIPTS_DIR}/S02_Preproc.${SBJ}_${SES}.sh                                                                          \
          -regress_compute_tsnr yes                                                                                                                            \
          -regress_make_cbucket yes                                                                                                                            \
          -bids_deriv yes                                                                                                                                      \
          -scr_overwrite

         # Add line for this subject to the Swarm file
         echo "module load afni; source /data/SFIMJGC_HCP7T/Apps/miniconda38/etc/profile.d/conda.sh && conda activate tedana_2024a; tcsh -xef ${AFNI_PROC_SCRIPTS_DIR}/S02_Preproc.${SBJ}_${SES}.sh 2>&1 | tee ${AFNI_PROC_SCRIPTS_DIR}/output.S02_Preproc.${SBJ}_${SES}.txt" >> ${SWARM_PATH}
    done
done

echo "============================================================================================"
echo " === SWARM FILE IN: ${SWARM_PATH}"
echo "============================================================================================"
