#!/bin/bash

# Root directory and subject code
ROOT_DIR="/path/to/armadillo/parent_directory" # Parent directory containing 'armadillo' folder
SUBJECT=$1                                     # Must enter subject code in terminal .eg 'srun sh update_subject.sh SC000'

cd $ROOT_DIR
cd armadillo
module load matlab

# Run MATLAB code without display
matlab -nodesktop -nodisplay -singleCompThread -r "update_subject('$ROOT_DIR', '$SUBJECT'); exit;"