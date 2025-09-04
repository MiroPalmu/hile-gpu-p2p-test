#!/bin/bash -l
#SBATCH --job-name=test
#SBATCH --output=slurm-%x.out 
#SBATCH --error=slurm-%x.err 
#SBATCH --open-mode=truncate
#SBATCH --partition=hile
#SBATCH --nodelist=hile-g0[1,2] # We use rocm 6.2 which is not on hile-g03.
#SBATCH --gres-flags=enforce-binding
#SBATCH --nodes=1
#SBATCH --gpus=2
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-gpu=8
#SBATCH --mem-per-cpu=2GB
#SBATCH --time=0-00:60:00       # Run time (d-hh:mm:ss)

source ./test_env.sh

cat << EOF > select_gpu
#!/bin/bash
export ROCR_VISIBLE_DEVICES=\$SLURM_LOCALID

exec \$*
EOF

chmod +x ./select_gpu

export MPICH_GPU_SUPPORT_ENABLED=1
# export MPICH_GPU_IPC_ENABLED=0 # slow but fixes p2p gpu comm

srun ./select_gpu ./main
 
rm -f ./select_gpu
