#!/bin/bash
#SBATCH --qos=short
#SBATCH --job-name=ModelSSTProcessing
#SBATCH --output=/p/tmp/baharem/slurm-%j.out
#SBATCH --error=/p/tmp/baharem/slurm-%j.err

target_grid="/p/tmp/baharem/New_June/Target_Grid"
#CESM2_tos="/p/tmp/bathiany/CMIP4BAHAR/tos_Omon_CESM2_piControl_r1i1p1f1.nc"
#MPI_tos="/p/tmp/baharem/October/MPI_retried/merged_tos.nc"
#MRI_tos="/p/tmp/baharem/October/MRI/tos_Omon_MRI-ESM2-0_piControl_r1i1p1f1_gn_185001-255012.nc"
#CanESM5_tos="/p/tmp/baharem/October/CanESM5_1000yr/merged_tos.nc"
HadGem3_tos_hist="/p/tmp/baharem/August_25/Statistically_Optimal_Fingerprints/merged_HadGem3_tos.nc"
# Array of model input paths
input_files=($HadGem3_tos_hist)
# Array of corresponding model names
model_names=("HadGem3")

# Loop through input files and process each model
for i in "${!input_files[@]}"; do
    input="${input_files[$i]}"
    model="${model_names[$i]}"
    
    # Set the output name based on the model and the analysis type
    dipole_output="/p/tmp/baharem/August_25/Statistically_Optimal_Fingerprints/Output_${model}_Dipole_hist.nc"
    caesar_output="/p/tmp/baharem/August_25/Statistically_Optimal_Fingerprints/Output_${model}_Caesar_hist.nc"
    spg_output="/p/tmp/baharem/August_25/Statistically_Optimal_Fingerprints/Output_${model}_SPG_hist.nc"

    regridded="/p/tmp/baharem/regridded_${model}.nc"
    caesar_spg="/p/tmp/baharem/caesar_${model}_spg.nc"
    temp_file="/p/tmp/baharem/temp_${model}.nc"
    temp_global="/p/tmp/baharem/temp_global_${model}.nc"
    monthly="/p/tmp/baharem/monthly_${model}.nc"
    avg_monthly="/p/tmp/baharem/avg_monthly_${model}.nc"
    avg_yearly_global="/p/tmp/baharem/avg_yearly_global_${model}.nc"
    avg_yearly_ceasar="/p/tmp/baharem/avg_yearly_ceasar_${model}.nc"
    NH_mean="/p/tmp/baharem/NH_mean_${model}.nc"

    #REGRID first
    cdo remapbil,$target_grid $input $regridded 

    #DIPOLE
    cdo -L sub -fldmean -sellonlatbox,-70,30,45,80 -selvar,tos $regridded -fldmean -sellonlatbox,-70,30,-45,0 -selvar,tos $regridded $dipole_output

    #CEASAR
   
    # Step 1: Choose Caesar region
    cdo -L -fldmean -sellonlatbox,-55,-20,46,61 -selvar,tos $regridded $caesar_spg || { echo "Error in Step 2: Selecting Caesar region failed for $model"; exit 1; }
    cdo -L -fldmean -selvar,tos $regridded $temp_file || { echo "Error in Step 2: Selecting global field mean failed for $model"; exit 1; }

    # Step 3: Select months November to May for Caesar region
    cdo selmon,11,12,1,2,3,4,5 $caesar_spg $monthly || { echo "Error in Step 3: Selecting Caesar months failed for $model"; exit 1; }

    # Step 4: Compute the time average over the selected months for Caesar region
    cdo yearmean $monthly $avg_monthly || { echo "Error in Step 4: Averaging Caesar months failed for $model"; exit 1; }

    # Step 5: Select months November to May for the global region
    cdo selmon,11,12,1,2,3,4,5 $temp_file $temp_global || { echo "Error in Step 5: Selecting global months failed for $model"; exit 1; }

    # Step 6: Compute the time average over the selected months for the global region
    cdo yearmean $temp_global $avg_yearly_global || { echo "Error in Step 6: Averaging global months failed for $model"; exit 1; }

    # Step 7: Subtract Caesar averages from global averages
    cdo sub $avg_monthly $avg_yearly_global $caesar_output || { echo "Error in Step 7: Subtraction failed for $model"; exit 1; }

    # Cleanup
    rm -f $temp_file $temp_global $monthly $avg_monthly $avg_yearly_global

    #SPG
    # Step 2: Choose Caesar region
    cdo -L -fldmean -sellonlatbox,-55,-20,46,61 -selvar,tos $regridded $caesar_spg || { echo "Error in Step 2: Selecting Caesar region failed for $model"; exit 1; }
    cdo -L -fldmean -sellonlatbox,-180,180,0,90 -selvar,tos $regridded $temp_file || { echo "Error in Step 2: Selecting global field mean failed for $model"; exit 1; }

    # Step 4: Compute the time average over the selected months for Caesar region
    cdo yearmean $caesar_spg $avg_yearly_ceasar || { echo "Error in Step 4: Averaging Caesar months failed for $model"; exit 1; }

    # Step 6: Compute the time average over the selected months for the global region
    cdo yearmean $temp_file  $NH_mean || { echo "Error in Step 6: Averaging global months failed for $model"; exit 1; }

    # Step 7: Subtract Caesar averages from global averages
    cdo sub $avg_yearly_ceasar $NH_mean $spg_output || { echo "Error in Step 7: Subtraction failed for $model"; exit 1; }

    # Cleanup
    rm -f $temp_file $avg_yearly_ceasar $NH_mean $caesar_spg $avg_yearly_ceasar
done
