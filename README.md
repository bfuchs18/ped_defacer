# ped_defacer
Scripts to apply a [pediatric defacer](https://github.com/d3b-center/pediatric-auto-defacer-public) to anatomical scans across studies

\
[code/ped_defacer.slurm](code/ped_defacer.slurm) is a script to run PedsAutoDefacer via a singularity container in Penn State's high-performance computing environment
  - running this script requires creating a singularity container with the PedsAutoDeface tool:
  ```bash
  # create container (update container name if 0.1.0 is no longer the latest version)
  singularity pull docker://afam00/peds-brain-auto-deface:latest peds-auto-deface-0.1.0.simg
  ```
  - This script will:
    -   create a persistent overlay to use the singularity container as if it is writable, avoiding permissions issues due to read-only directories
    -   run [code/_copy_input.py](code/_copy_input.py) to copy anatomical files from project directories into data/input/
    -   run PedsAutoDefacer via a singularity, defacing nii in data/input/ and saving de-faced images in data/output/
