#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=10
#SBATCH --mem-per-cpu=10GB
#SBATCH --time=24:00:00
#SBATCH --partition=open
#SBATCH --output=%x.%j.out

# echo script contents into slurm output
echo "Peds Auto Defacer SLURM script"
echo "--------------------"
cat "$0"
echo "--------------------"

#User inputs:
defacer_dir="/storage/group/klk37/default/ped_defacer/"
singularity_dir="/storage/group/klk37/default/sw/"

unset PYTHONPATH

# create overlay image if it doesnt exist -- overlay image will be used to avoid write permissions issues when running singularity
if ! [ -f "$defacer_dir/code/overlay.img" ]; then
    echo "Creating overlay image"
    cd "$defacer_dir/code"
    dd if=/dev/zero of=overlay.img bs=1M count=512
    mkfs.ext3 overlay.img
fi

# copy anatomical files to deface from different projects into defacer_dir
echo ""
echo "Running copy_input.py to copy anatomical images into peds_defacer/data/input/"
echo ""
python3 "$defacer_dir/code/_copy_input.py"

# Run defacer
echo ""
echo "Running Peds Auto Defacer"
echo ""

# create output directory if it doesnt exist
if ! [ -d "$defacer_dir/data/output" ]; then
    mkdir -p "$defacer_dir/data/output"
fi

# run singularity container
## set working directory as container root with --pwd / ... otherwise looks for run.py script in folder that singularity is run from (not in the container)

singularity run --overlay $defacer_dir/code/overlay.img --fakeroot -B $defacer_dir/data/input:/input -B $defacer_dir/data/output:/output --pwd / $singularity_dir/peds-auto-deface-0.1.0.simg
