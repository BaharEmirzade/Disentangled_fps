#!/bin/bash
#SBATCH --qos=short
#SBATCH --job-name=ModelSSTProcessing
#SBATCH --output=/p/tmp/baharem/slurm-%j.out
#SBATCH --error=/p/tmp/baharem/slurm-%j.err

target_grid="/p/tmp/baharem/New_June/Target_Grid"
HadISST="/p/tmp/baharem/August_25/HadISST_trimmed.nc"

# Set the output name based on the the analysis type
dipole_output="/p/tmp/baharem/August_25/Statistically_Optimal_Fingerprints/Output_HadISST_Dipole.nc"
caesar_output="/p/tmp/baharem/August_25/Statistically_Optimal_Fingerprints/Output_HadISST_Caesar.nc"
spg_output="/p/tmp/baharem/August_25/Statistically_Optimal_Fingerprints/Output_HadISST_SPG.nc"

regridded="/p/tmp/baharem/regridded_HadISST.nc"
caesar_spg="/p/tmp/baharem/caesar_HadISST_spg.nc"
temp_file="/p/tmp/baharem/temp_HadISST.nc"
temp_global="/p/tmp/baharem/temp_global_HadISST.nc"
monthly="/p/tmp/baharem/monthly_HadISST.nc"
avg_monthly="/p/tmp/baharem/avg_monthly_HadISST.nc"
avg_yearly_global="/p/tmp/baharem/avg_yearly_global_HadISST.nc"
avg_yearly_ceasar="/p/tmp/baharem/avg_yearly_ceasar_HadISST.nc"
NH_mean="/p/tmp/baharem/NH_mean_HadISST.nc"
HadISST_clean="/p/tmp/baharem/HadISST_clean.nc"
dipole_temp="/p/tmp/baharem/dipole_temp"

cdo setrtomiss,-1e20,-900 $HadISST $HadISST_clean
#REGRID first
cdo remapbil,$target_grid $HadISST_clean $regridded

#DIPOLE
cdo -L sub -fldmean -sellonlatbox,-70,30,45,80 -selvar,sst $regridded -fldmean -sellonlatbox,-70,30,-45,0 -selvar,sst $regridded $dipole_temp
cdo yearmean $dipole_temp $dipole_output
#CEASAR

# Step 1: Choose Caesar region
cdo -L -fldmean -sellonlatbox,-55,-20,46,61 -selvar,sst $regridded $caesar_spg || { echo "Error in Step 2: Selecting Caesar region failed for $model"; exit 1; }
cdo -L -fldmean -selvar,sst $regridded $temp_file || { echo "Error in Step 2: Selecting global field mean failed"; exit 1; }

# Step 3: Select months November to May for Caesar region
cdo selmon,11,12,1,2,3,4,5 $caesar_spg $monthly || { echo "Error in Step 3: Selecting Caesar months failed"; exit 1; }

# Step 4: Compute the time average over the selected months for Caesar region
cdo yearmean $monthly $avg_monthly || { echo "Error in Step 4: Averaging Caesar months failed"; exit 1; }

# Step 5: Select months November to May for the global region
cdo selmon,11,12,1,2,3,4,5 $temp_file $temp_global || { echo "Error in Step 5: Selecting global months failed"; exit 1; }

# Step 6: Compute the time average over the selected months for the global region
cdo yearmean $temp_global $avg_yearly_global || { echo "Error in Step 6: Averaging global months failed"; exit 1; }

# Step 7: Subtract Caesar averages from global averages
cdo sub $avg_monthly $avg_yearly_global $caesar_output || { echo "Error in Step 7: Subtraction failed"; exit 1; }

# Cleanup
rm -f $dipole_temp $temp_file $temp_global $monthly $HadISST_clean $avg_monthly $avg_yearly_global

#SPG
# Step 2: Choose Caesar region
cdo -L -fldmean -sellonlatbox,-55,-20,46,61 -selvar,sst $regridded $caesar_spg || { echo "Error in Step 2: Selecting Caesar region"; exit 1; }
cdo -L -fldmean -sellonlatbox,-180,180,0,90 -selvar,sst $regridded $temp_file || { echo "Error in Step 2: Selecting global field mean failed"; exit 1; }
# Step 4: Compute the time average over the selected months for Caesar region
cdo yearmean $caesar_spg $avg_yearly_ceasar || { echo "Error in Step 4: Averaging Caesar months failed"; exit 1; }

# Step 6: Compute the time average over the selected months for the global region
cdo yearmean $temp_file  $NH_mean || { echo "Error in Step 6: Averaging global months failed"; exit 1; }

# Step 7: Subtract Caesar averages from global averages
cdo sub $avg_yearly_ceasar $NH_mean $spg_output || { echo "Error in Step 7: Subtraction failed"; exit 1; }

# Cleanup
rm -f $temp_file $avg_yearly_ceasar $NH_mean $caesar_spg $avg_yearly_ceasar
