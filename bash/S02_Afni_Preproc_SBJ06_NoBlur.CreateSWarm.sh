set -e

module load afni

TESTDRIVE='no'
PRJDIR='/data/SFIMJGC/Misha'   # Project directory: includes Scripts, Freesurfer and PrcsData folders

PRCSDATA_DIR=`echo ${PRJDIR}/prcs_data`
ORIGDATA_DIR=`echo ${PRJDIR}/orig_data`
SUBJECTS_DIR=`echo ${PRJDIR}/freesurfer/`
RESOURCES_DIR=`echo ${PRJDIR}/resources/`
SCRIPTS_DIR=`echo ${PRJDIR}/code/bash/`
USERNAME=`whoami`
SWARM_PATH=`echo ${PRJDIR}/swarm.${USERNAME}/S02_Preproc_fMRI_SBJ06_NoBlur.SWARM.sh`
LOGS_DIR=`echo ${PRJDIR}/logs.${USERNAME}/S02_Preproc_fMRI_SBJ06_NoBlur.logs`
subjects=(SBJ06_Day01 SBJ06_Day02)
num_subjects=`echo ${#subjects[@]}`
echo "++ Subjects: ${subjects[@]}"
echo " + number of subjects = ${num_subjects}"
echo "++ Orig Data Folder  : ${PRCSDATA_DIR}"
echo "++ Scripts Folder    : ${SCRIPTS_DIR}"
echo "++ Swarm Folder      : ${SWARM_PATH}"
echo "++ Logs Folder       : ${LOGS_DIR}"
echo "++ Freesurfer Folder : ${SUBJECTS_DIR}"

# Initialize Swarm File
# ---------------------
echo "#Creation Time: `date`" > ${SWARM_PATH}
echo "#Creation Time: `date`" > ${RESOURCES_DIR}/S02_NotAvailable.txt
echo "#Creation Time: `date`" > ${RESOURCES_DIR}/S02_WillTry.txt
echo "#swarm -f ${SWARM_PATH} -g 32 -t 32 --time 48:00:00 --module afni --logdir ${LOGS_DIR} --sbatch \"--export AFNI_COMPRESSOR=GZIP\"" >> ${SWARM_PATH}

# Create log directory if needed (for swarm files)
# ------------------------------------------------
if [ ! -d ${LOGS_DIR} ]; then 
   mkdir -p ${LOGS_DIR}
fi

# Create directory for all fMRI data processing files per subject if needed
# -------------------------------------------------------------------------
if [ ! -d S02_Afni_Preproc_fMRI ]; then 
   mkdir S02_Afni_Preproc_fMRI
fi

# Copy and process all fMRI data
# ------------------------------
echo "++ INFO: Entering loop (through subjects....)"
for SBJ in ${subjects[@]}
do
    ANAT_PROC_DIR=`echo ${PRCSDATA_DIR}/${SBJ}/D01_Anatomical`
    echo "${SBJ} --> ${ANAT_PROC_DIR}"
    if [ ! -f ${ANAT_PROC_DIR}/anatQQ.${SBJ}.nii ] || [ ! -f ${ANAT_PROC_DIR}/anatSS.${SBJ}.nii ]; then
       echo "${SBJ}" >> ${RESOURCES_DIR}/S02_NotAvailable.txt
       echo "${SBJ}" 
    else
       echo "${SBJ}" >> ${RESOURCES_DIR}/S02_WillTry.txt
       OUT_DIR=`echo ${PRCSDATA_DIR}/${SBJ}/D02_Preproc_fMRI_NoBlur`
       echo "HELLO"
       if [ "$TESTDRIVE" == "no" ]; then
          afni_proc.py                                                                                          \
                   -subj_id ${SBJ}                                                                              \
                   -blocks despike tshift align tlrc volreg mask combine scale regress                          \
                   -radial_correlate_blocks tcat volreg                                                         \
                   -copy_anat ${ANAT_PROC_DIR}/anatSS.${SBJ}.nii                                                \
                   -anat_has_skull no                                                                           \
                   -anat_follower anat_w_skull anat ${ANAT_PROC_DIR}/anatUAC.${SBJ}.nii                         \
                   -anat_follower_ROI aaseg  anat ${SUBJECTS_DIR}/${SBJ}/SUMA/aparc.a2009s+aseg.nii.gz          \
                   -anat_follower_ROI aeseg  epi  ${SUBJECTS_DIR}/${SBJ}/SUMA/aparc.a2009s+aseg.nii.gz          \
                   -anat_follower_ROI FSvent epi  ${SUBJECTS_DIR}/${SBJ}/SUMA/fs_ap_latvent.nii.gz              \
                   -anat_follower_ROI FSWe   epi  ${SUBJECTS_DIR}/${SBJ}/SUMA/fs_ap_wm.nii.gz                   \
                   -anat_follower_ROI lhRib  epi  ${SUBJECTS_DIR}/${SBJ}/SUMA/lh.ribbon.nii.gz                  \
                   -anat_follower_ROI rhRib  epi  ${SUBJECTS_DIR}/${SBJ}/SUMA/rh.ribbon.nii.gz                  \
                   -anat_follower_erode FSvent FSWe                                                             \
                   -tcat_remove_first_trs 0                                                                     \
                   -tshift_interp -wsinc9                                                                       \
                   -dsets_me_echo ${ORIGDATA_DIR}/${SBJ}/${SBJ}_Run0?_E01.nii.gz                                \
                   -dsets_me_echo ${ORIGDATA_DIR}/${SBJ}/${SBJ}_Run0?_E02.nii.gz                                \
                   -dsets_me_echo ${ORIGDATA_DIR}/${SBJ}/${SBJ}_Run0?_E03.nii.gz                                \
                   -echo_times `cat ${ORIGDATA_DIR}/${SBJ}/${SBJ}_Rest_Echoes.1D`                               \
                   -blip_reverse_dset ${ORIGDATA_DIR}/${SBJ}/${SBJ}_RevFlip_E02.nii.gz'[0]'                     \
                   -blip_forward_dset ${ORIGDATA_DIR}/${SBJ}/${SBJ}_Run01_E02.nii.gz'[0]'                       \
                   -reg_echo 2                                                                                  \
                   -combine_method m_tedana                                                                     \
                   -combine_opts_tedana "--mask mask_group+tlrc.HEAD"                                           \
                   -align_unifize_epi local                                                                     \
                   -align_opts_aea -cost lpc+ZZ -giant_move -check_flip                                         \
                   -tlrc_base MNI152_2009_template_SSW.nii.gz                                                   \
                   -tlrc_NL_warp                                                                                \
                   -tlrc_NL_warped_dsets ${ANAT_PROC_DIR}/anatQQ.${SBJ}.nii                                     \
                                         ${ANAT_PROC_DIR}/anatQQ.${SBJ}.aff12.1D                                \
                                         ${ANAT_PROC_DIR}/anatQQ.${SBJ}_WARP.nii                                \
                   -volreg_align_to MIN_OUTLIER                                                                 \
                   -volreg_align_e2a                                                                            \
                   -volreg_tlrc_warp                                                                            \
                   -volreg_warp_dxyz 2.5                                                                        \
                   -volreg_warp_final_interp  wsinc5                                                            \
                   -volreg_compute_tsnr       yes                                                               \
                   -mask_epi_anat yes                                                                           \
                   -regress_opts_3dD -jobs 32                                                                   \
                   -regress_motion_per_run                                                                      \
                   -regress_ROI_PC FSvent 3                                                                     \
                   -regress_ROI_PC_per_run FSvent                                                               \
                   -regress_make_corr_vols aeseg FSvent                                                         \
                   -regress_anaticor_fast                                                                       \
                   -regress_anaticor_label FSWe                                                                 \
                   -regress_censor_motion 0.4                                                                   \
                   -regress_censor_outliers 0.05                                                                \
                   -regress_apply_mot_types demean deriv                                                        \
                   -regress_polort 4                                                                            \
                   -regress_bandpass 0.01 0.2                                                                   \
                   -regress_run_clustsim no                                                                     \
                   -html_review_style pythonic                                                                  \
                   -out_dir ${OUT_DIR}                                                                          \
                   -script ${SCRIPTS_DIR}/S02_Afni_Preproc_fMRI/S02_Preproc_fMRI_NoBlur.${SBJ}.sh               \
                   -regress_compute_tsnr yes                                                                    \
                   -regress_make_cbucket yes                                                                    \
                   -scr_overwrite

            # Add line for this subject to the Swarm file
            echo "module load afni; source /data/SFIMJGC_HCP7T/Apps/miniconda38/etc/profile.d/conda.sh && conda activate tedana_2024a; tcsh -xef ${SCRIPTS_DIR}/S02_Afni_Preproc_fMRI/S02_Preproc_fMRI_NoBlur.${SBJ}.sh 2>&1 | tee ${SCRIPTS_DIR}/S02_Afni_Preproc_fMRI/output.S02_Preproc_fMRI_SBJ05_Rest01_NoBlur.${SBJ}.txt" >> ${SWARM_PATH}
       fi
    fi
done

echo "============================================================================================"
echo " === SWARM FILE IN: ${SWARM_PATH}"
echo "============================================================================================"
#                   -regress_bandpass 0.01 0.2                                                                   \
