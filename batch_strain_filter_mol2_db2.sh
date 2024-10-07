#!/bin/bash

# Function to display the help message
show_help() {
    echo "Usage: $0 [TARGET_DIRECTORY]"
    echo
    echo "This script processes .mol2 and .db2 files in the current working directory."
    echo "For each .mol2 or .db2 file, it launches a job on the HPC cluster to run the Torsion Strain script."
    echo
    echo "For more info and the code this script execute see https://wiki.docking.org/index.php?title=TLDR:strain and https://github.com/docking-org/ChemInfTools/tree/master/apps/strainfilter" 
    echo
    echo "Options:"
    echo "  TARGET_DIRECTORY   Name of the target directory to store the new directories."
    echo "                     If not provided, defaults to 'processed_files' under the current working directory."
    echo "  -h, --help         Display this help message and exit."
}

# Check if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Use the current working directory as the source directory
SOURCE_DIRECTORY="$(pwd)"
if [ $? -ne 0 ]; then
    echo "ERROR: Unable to retrieve the current directory. Please check permissions."
    exit 1
fi

# Check if the target directory name is provided as an argument
if [ -z "$1" ]; then
    TARGET_DIRECTORY="$SOURCE_DIRECTORY/processed_files"  # Default to home directory
else
    TARGET_DIRECTORY="$SOURCE_DIRECTORY/$1"
fi

# Create the target directory if it doesn't exist
if [ ! -d "$TARGET_DIRECTORY" ]; then
    mkdir -p "$TARGET_DIRECTORY"
    if [ $? -ne 0 ]; then
        echo "ERROR: Unable to create directory '$TARGET_DIRECTORY'. Check permissions."
        exit 1
    fi
fi

# Create subdirectories for logs and errors
LOG_DIRECTORY="$TARGET_DIRECTORY/logs"
ERROR_DIRECTORY="$TARGET_DIRECTORY/errors"

mkdir -p "$LOG_DIRECTORY" "$ERROR_DIRECTORY"
if [ $? -ne 0 ]; then
    echo "ERROR: Unable to create log or error directories. Check permissions."
    exit 1
fi

# Load the necessary module for strainfilter
module load strainfilter
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to load strainfilter module. Check module availability."
    exit 1
fi

# Process all .mol2 files
for MOL2_FILE in "$SOURCE_DIRECTORY"/*.mol2; 
do
    # Skip if no .mol2 files are found
    if [ ! -f "$MOL2_FILE" ]; then
        continue
    fi

    # Extract the base filename without path and extension
    BASENAME=$(basename "$MOL2_FILE" .mol2)

    echo "Submitting job for $BASENAME..."

    # Submit the job using bsub with the command to run Torsion_Strain.py
    bsub -q standard -n 1 -R "rusage[mem=2GB]" -P strainfilter \
         -o "$LOG_DIRECTORY/${BASENAME}.out" \
         -e "$ERROR_DIRECTORY/${BASENAME}.err" \
         -J "$BASENAME-strainfilter" \
         "Torsion_Strain.py \"$MOL2_FILE\""

    echo "Job for $BASENAME submitted."
done

# Process all .db2 files
for DB2_FILE in "$SOURCE_DIRECTORY"/*.db2; 
do
    # Skip if no .db2 files are found
    if [ ! -f "$DB2_FILE" ]; then
        continue
    fi

    # Extract the base filename without path and extension
    BASENAME=$(basename "$DB2_FILE" .db2)

    echo "Submitting job for $BASENAME..."

    # Submit the job using bsub with the command to run Torsion_Strain.py
    bsub -q standard -n 1 -R "rusage[mem=2GB]" -P strainfilter \
         -o "$LOG_DIRECTORY/${BASENAME}.out" \
         -e "$ERROR_DIRECTORY/${BASENAME}.err" \
         -J "$BASENAME-strainfilter" \
         "Torsion_Strain.py \"$DB2_FILE\""

    echo "Job for $BASENAME submitted."
done

# Check if no files were processed
if [ ! -n "$(find "$SOURCE_DIRECTORY" -name '*.mol2' -o -name '*.db2')" ]; then
    echo "No .mol2 or .db2 files found in $SOURCE_DIRECTORY"
fi
