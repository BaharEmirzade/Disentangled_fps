# Disentangled_fps
Disentangled Fingerprints suggest no historical weakening of Atlantic Overturning and Subpolar Gyre
All code and processing are outlined, below as well as on their respective jupyter notebooks. 
Some of the processed files are too big to include in the repo hence only some are present, yet all can be processed by following the methodology. 

All data was downloaded from ESGF MetaGrid

AMOC and SPG Timeseries Processing
- msftmz or msftyz variable downloaded for AMOC 
- msftbarot parameter downloaded for SPG
- An example of the bash script processing file is added as Process_MPI_moc. This is the same method used
for processing msftbarot files. 
- After this the Processing.ipynb jupyter notebook is run. 

SOS and TOS timeseries Processing
- sos and tos variables downloaded
- Bash script similar to the one named Process_MPI
- Again the same Processing.ipynb jupyter notebook is run

Note on variables, as outlined in Jackson (2020) initially my variables were labelled as follows:
SST_{SG-G}:SST_caesar 
SST_{SG-NH}: Subpolar gyre (SPG) region (as SST_caesar) minus NH
mean SST
SST_{DP}:Dipole Fingerprint


For any questions please feel free to email bahar.emirzade@tum.de
