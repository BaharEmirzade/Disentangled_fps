#!/bin/bash
#SBATCH --job-name=processing
#SBATCH --output=processing_%j.out
#SBATCH --error=processing_%j.err
#SBATCH --qos=priority

module load cdo

INPUT="/p/tmp/baharem/Statistically_Optimal_Fingerprints"
OUTPUT="/p/tmp/baharem/Statistically_Optimal_Fingerprints/processing"

# Variables to process
VARIABLES=("tos" "sos" "msftmz" "msftyz" "msftbarot")

# Models
MODELS=("CanESM5" "CESM2" "HadGEM3-GC31-LL" "MPI-ESM1-2-LR" "MRI-ESM2-0")

# Target grid file (modify to your grid)
TARGET_GRID="/p/tmp/baharem/New_June/Target_Grid"

# Experiments
EXPS=("historical" "piControl")

for var in "${VARIABLES[@]}"; do
    echo "=== Processing variable: $var ==="

    for model in "${MODELS[@]}"; do
        echo "  Model: $model"

        for exp in "${EXPS[@]}"; do
            echo "    Experiment: $exp"

            # File pattern
            pattern="${INPUT}/${var}_Omon_${model}_${exp}_*.nc"
            out_merged="${OUTPUT}/${var}_${model}_${exp}_merged.nc"
            out_yearmean="${OUTPUT}/${var}_${model}_${exp}_yearmean.nc"
            out_remap="${OUTPUT}/${var}_${model}_${exp}_remap.nc"

            # Check if files exist
            files=$(ls $pattern 2>/dev/null)
            if [ -z "$files" ]; then
                echo "      No files found"
                continue
            fi

            echo "      Merging time..."
            cdo mergetime $pattern $out_merged

            echo "      Computing yearmean..."
            cdo yearmean $out_merged $out_yearmean

            echo "      Remapping to target grid..."
            cdo remapbil,$TARGET_GRID $out_yearmean $out_remap

            echo "      Done: $out_remap"
        done
    done
done

echo "All processing completed."

