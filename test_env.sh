module purge
module load cpe/24.11

# After cpe we don't specify versions as cpe module makes defaults be sensible.
module load PrgEnv-cray craype-accel-amd-gfx90a cray-mpich libfabric rocm cray-python cray-pmi
# module load PrgEnv-amd craype-accel-amd-gfx90a craype-network-ucx libfabric rocm cray-python cray-pmi
# module swap cray-mpich cray-mpich-ucx


module list

export PYTHONPATH="$PYTHONPATH:/wrk-vakka/users/pamiro/hip_tests/build"
