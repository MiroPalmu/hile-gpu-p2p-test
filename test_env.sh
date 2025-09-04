module purge
module load cpe/24.11

# After cpe we don't specify versions as cpe module makes defaults be sensible.
module load PrgEnv-cray craype-accel-amd-gfx90a cray-mpich libfabric
module list
