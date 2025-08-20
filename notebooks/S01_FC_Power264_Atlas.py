# ---
# jupyter:
#   jupytext:
#     formats: ipynb,py:light
#     text_representation:
#       extension: .py
#       format_name: light
#       format_version: '1.5'
#       jupytext_version: 1.15.2
#   kernelspec:
#     display_name: BOLD WAVES 2024a
#     language: python
#     name: bold_waves_2024a
# ---

from nilearn.datasets import fetch_coords_power_2011
ATLASES_DIR = '/data/SFIMJGC/Misha/atlases/'
import os
import os.path as osp
import pandas as pd
import numpy as np
import seaborn as sns

# ***
# ## 1. Download Atlas ROI positions

color_map_dict={'White':'#ffffff','Cyan':'#E0FFFF','Orange':'#FFA500','Purple':'#800080',
                'Pink':'#FFC0CB','Red':'#ff0000','Gray':'#808080','Teal':'#008080','Brown':'#A52A2A',
                'Blue':'#0000ff','Yellow':'#FFFF00','Black':'#000000','Pale blue':'#ADD8E6','Green':'#00ff00'}
nw_color_dict = {'Uncertain':'#ffffff',
                 'Sensory/somatomotor Hand':'#E0FFFF',
                 'Sensory/somatomotor Mouth':'#FFA500',
                 'Cingulo-opercular Task Control':'#800080',
                 'Auditory':'#FFC0CB', 
                 'Default mode':'#ff0000',
                 'Memory retrieval?':'#808080',
                 'Ventral attention':'#008080', 
                 'Visual':'#0000ff',
                 'Fronto-parietal Task Control':'#FFFF00',
                 'Salience':'#000000', 
                 'Subcortical':'#A52A2A',
                 'Cerebellar':'#ADD8E6', 
                 'Dorsal attention':'#00ff00'}

power_atlas_info = fetch_coords_power_2011(False)

power_atlas_info['rois'].head(5)

# ***
# ## 2. Create ROIs in AFNI

ATLAS_NAME='Power264'
ATLAS_DIR = osp.join(ATLASES_DIR,ATLAS_NAME)

if not osp.exists(ATLAS_DIR):
    os.makedirs(ATLAS_DIR)

roi_centers_path = osp.join(ATLAS_DIR,f'{ATLAS_NAME}.roi_coords.MNI.csv')
power_atlas_info['rois'][['x','y','z','roi']].to_csv(roi_centers_path, header=None, index=None)

roi_info_df = power_atlas_info['rois'].copy()
roi_info_df.columns = ['ROI_ID','pos_R','pos_A','pos_S']
roi_info_df['ROI_Name'] = ['ROI'+str(r).zfill(3) for r in roi_info_df['ROI_ID']]
roi_info_df = roi_info_df[['ROI_ID','ROI_Name','pos_R','pos_A','pos_S']]
print(roi_info_df.shape)
roi_info_df.head(5)

# Run the following code to generate an AFNI file with the ROIs from the Power 264 Atlas.
# ```bash
# ml afni
# # cd /data/SFIMJGC/Misha/atlases/Power264
# 3dUndump -overwrite \
#              -prefix Power264.nii.gz \
#              -master ../../prcs_data/SBJ01/D02_Preproc_fMRI/errts.SBJ01.fanaticor+tlrc.HEAD \
#              -xyz \
#              -srad 5 \
#              -xyz Power264.roi_coords.MNI.csv
# ```

# ***
#
# ## 3. Compute FC matrices for the two subjects

# Next, to compute the static connectivity matrix:
#
# ```bash
# # cd /data/SFIMJGC/Misha/prcs_data/SBJ01/D02_Preproc_fMRI/
# 3dNetCorr -overwrite -in_rois ../../../atlases/Power264/Power264.nii.gz -output_mask_nonnull -inset errts.SBJ01.tproject+tlrc.HEAD  -prefix errts.SBJ01.tproject.Power264
#
# # cd /data/SFIMJGC/Misha/prcs_data/SBJ02/D02_Preproc_fMRI/
# 3dNetCorr -overwrite -in_rois ../../../atlases/Power264/Power264.nii.gz -output_mask_nonnull -inset errts.SBJ02.tproject+tlrc.HEAD  -prefix errts.SBJ02.tproject.Power264
# ```

# ***
#
# ## 4. Plotting of FC matrices

# Now, let's visualize the resulting matrices

from sfim_lib.io.afni import load_netcc
from sfim_lib.plotting.fc_matrices import hvplot_fc

fc = {}
fc['SBJ01'] = load_netcc('/data/SFIMJGC/Misha/prcs_data/SBJ01/D02_Preproc_fMRI/errts.SBJ01.tproject.Power264_000.netcc')
fc['SBJ02'] = load_netcc('/data/SFIMJGC/Misha/prcs_data/SBJ02/D02_Preproc_fMRI/errts.SBJ02.tproject.Power264_000.netcc')

power_atlas_addinfo_path = osp.join(ATLAS_DIR,'additional_files','Neuron_consensus_264.xlsx')
power_atlas_addinfo = pd.read_excel(power_atlas_addinfo_path, header=[0], skiprows=[1])

roi_info_df['Network']= power_atlas_addinfo['Suggested System']
roi_info_df['Hemisphere'] = ['LH' if a<=0 else 'RH' for a in roi_info_df['pos_R']]
roi_info_df['RGB'] = [color_map_dict[c] for c in power_atlas_addinfo['Unnamed: 34']]
roi_info_df.head(5)

fc_df={}
for sbj in ['SBJ01','SBJ02']:
    fc_df[sbj] = pd.DataFrame(fc[sbj].values,
                           index = roi_info_df.set_index(['ROI_Name','ROI_ID','Hemisphere','Network']).index,
                           columns= roi_info_df.set_index(['ROI_Name','ROI_ID','Hemisphere','Network']).index)

hvplot_fc(fc_df['SBJ01'], net_cmap=nw_color_dict, by='Network',major_label_overrides='regular_grid', cmap='RdBu_r', cbar_title_fontsize=15, ticks_font_size=12, cbar_title='FC for JacSte:') + \
hvplot_fc(fc_df['SBJ02'], net_cmap=nw_color_dict, by='Network',major_label_overrides='regular_grid', cmap='RdBu_r', cbar_title_fontsize=15, ticks_font_size=12, cbar_title='FC for JosRas:')
