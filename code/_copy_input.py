#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
This script copies anatomical scans from other project's souredata folders into ped_defacer/data/input/ in preparation for running PedsAutoDeface tool
It is called by ped_defacer.slurm

@author: baf44
"""
## sync from local to Roar Collab
# cd /Users/baf44/projects
# rsync -av --update ped_defacer baf44@submit.hpc.psu.edu:/storage/group/klk37/default/

# Usage: python3 _copy_input.py

###############
### Set up ####
###############

#set up packages    
import os
from pathlib import Path
import shutil

# define strings with paths to lab and defacer input directories on Roar Collab
lab_dir = os.path.join('/storage', 'group', 'klk37', 'default')
defacer_input_dir = os.path.join(lab_dir, 'ped_defacer', 'data', 'input')

# make directory to copy anatomical files into 
Path(defacer_input_dir).mkdir(parents=True, exist_ok=True)

# create dictionary with keys for each project and project [label, bids_folder_name] as value
project_mapping = {
    'R01_Marketing' : ['reach', 'bids'],
    'R01_Food_Brain_Study' : ['foodbrain', 'BIDS']
}

############################################################
### Copy anat files for each project in project_mapping ####
############################################################

for project_folder in project_mapping:

    print("Copying files for project " + project_folder)

    #define path to project bids/sourcedata directory 
    bids_folder = project_mapping[project_folder][1]
    project_source_dir = os.path.join(lab_dir, project_folder, bids_folder, 'sourcedata')

    #find all dicom source dirs
    source_dicom_dirs = list(Path(project_source_dir).rglob('sub-*/ses-1/dicom'))

    # get list of subs with dicom source dirs
    ##pathlib library -- .relative_to give path that follows project_source_dir; .parts[0] extracts the first directory in remaining path to get list of subjects
    subs = [item.relative_to(project_source_dir).parts[0] for item in source_dicom_dirs] 
    sub_ids = list(set([item[4:7] for item in subs])) # extract ID only from 'sub-{ID}'

    # for each sub
    for sub in sub_ids:

        # define subject nii directory
        sub_nii_dir = os.path.join(project_source_dir, 'sub-' + str(sub),  'ses-1', 'dicom', 'nii')

        # get list of anat files
        anat_files = list(Path(sub_nii_dir).rglob('*T1_MPRage_Sagittal.*')) # includes all file extensions (nii and json)
        
        # count number of nii files -- will be >1 if scan was repeated (e.g., due to quality concerns)
        nii_count1 = sum(1 for file in anat_files if file.suffix == '.nii')

        # if more than 1 nii file
        if nii_count1 > 1:

            # set path to subject dicom directory
            sub_dicom_dir = os.path.join(project_source_dir, 'sub-' + str(sub),  'ses-1', 'dicom')

            # get dicom/ser* directories associated with each nii
            for anat_file in anat_files:

                if anat_file.suffix == '.nii':

                    # get number of 'ser' directory associated with file based on integer that prefixes filename
                    basename = os.path.basename(anat_file) # also the basename of the json
                    ser_num = basename.split('_')[0]

                    # define string with how ser directory would be named if this nii was deemed "extra" (i.e., not the mprage to processe) based on visual inspection
                    extra_ser_dir = os.path.join(sub_dicom_dir, 'ser' + str(ser_num) + '_extra')
                    
                    # if ser dir has been labeled with "extra" for this nii
                    if Path(extra_ser_dir).exists():

                        # remove files from anat_files that start with ser_num
                        anat_files = [file for file in anat_files if not os.path.basename(file).startswith(ser_num + '_')]

        # get a new count of nii files
        ## the count will be 1 if only 1 nii ever existed, or because others were removed from anat_files due to ser dir being labeled "extra"
        nii_count2 = sum(1 for file in anat_files if file.suffix == '.nii')

        if nii_count2 == 1:

            for anat_file in anat_files:

                # define how to name file copied into input/
                file_extension = Path(anat_file).suffix # get file extention (nii or json)
                file_basename = project_mapping[project_folder][0] + '-' + str(sub) + '_t1'
                output_file = os.path.join(defacer_input_dir, file_basename + file_extension)
                
                # copy anat_file to output_file if output_file doesnt exist 
                if not Path(output_file).exists():
                    print("copying " + str(anat_file))
                    shutil.copy(anat_file, output_file)
                else: 
                    print(str(anat_file) + " already copied")

        elif nii_count2 > 1:
            print("multiple nii files remain")
