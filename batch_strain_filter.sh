#!/bin/bash

# Function to display the help message
show_help() {
    echo "Usage: $0 [TARGET_DIRECTORY]"
    echo
    echo "This script processes .mol2 and .db2 files in the current working directory."
    echo "For each .mol2 or .db2 file, it launches a job on the HPC cluster to run the Torsion Strain script."
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
    TARGET_DIRECTORY="$HOME/processed_files"  # Default to home directory
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

# Loop through each .mol2 and .db2 file in the source directory
for FILE in "$SOURCE_DIRECTORY"/*.{mol2,db2}; 
do
    if [ ! -f "$FILE" ]; then
        echo "No .mol2 or .db2 files found in $SOURCE_DIRECTORY"
        break
    fi

    # Extract the base filename without path and extension
    BASENAME=$(basename "$FILE" .mol2)
    BASENAME=$(basename "$BASENAME" .db2)

    echo "Submitting job for $BASENAME..."

    # Submit the job using bsub with log, error, and job name options
    bsub -q standard -n 1 -R "rusage[mem=2GB]" -P strainfilter \
         -o "$LOG_DIRECTORY/${BASENAME}.out" \
         -e "$ERROR_DIRECTORY/${BASENAME}.err" \
         -J "$BASENAME-strainfilter" \
         "$FILE"

    echo "Job for $BASENAME submitted."
done
