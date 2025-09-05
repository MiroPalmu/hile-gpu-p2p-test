This repo contains test code for inter node gpu to gpu MPI communication on Hile (hel-astro-lab/University of Helsinki cluster).
It reporoduces a bug which is described below (it is orginally the bug report on our internal site).

# Description

I have been trying to get gpu aware MPI working on Hile. However, if the message size is large enough to trigger IPC communication mechanism I will get following errors:

```
GTL_DEBUG: [0] hsa_amd_ipc_memory_create (in gtlt_hsa_ops.c at line 1650): HSA_STATUS_ERROR_INVALID_ARGUMENT: One of the actual arguments does not meet a precondition stated in the documentation of the corresponding formal argument.
MPICH ERROR [Rank 0] [job id 63800.1] [Thu Sep  4 10:29:04 2025] [hile-g01] - Abort(338288898) (rank 0 in comm 0): Fatal error in PMPI_Send: Invalid count, error stack:
PMPI_Send(163).......................: MPI_Send(buf=0x7f1e92200000, count=1024, MPI_INT, dest=1, tag=123, MPI_COMM_WORLD) failed
MPID_Send(505).......................: 
MPIDI_send_unsafe(64)................: 
MPIDI_SHM_mpi_isend(323).............: 
MPIDI_CRAY_Common_lmt_isend(84)......: 
MPIDI_CRAY_Common_lmt_export_mem(103): 
(unknown)(): Invalid count

aborting job:
Fatal error in PMPI_Send: Invalid count, error stack:
PMPI_Send(163).......................: MPI_Send(buf=0x7f1e92200000, count=1024, MPI_INT, dest=1, tag=123, MPI_COMM_WORLD) failed
MPID_Send(505).......................: 
MPIDI_send_unsafe(64)................: 
MPIDI_SHM_mpi_isend(323).............: 
MPIDI_CRAY_Common_lmt_isend(84)......: 
MPIDI_CRAY_Common_lmt_export_mem(103): 
(unknown)(): Invalid count
```

# Test setup

All the code and slurm scripts can be found at: https://github.com/MiroPalmu/hile-gpu-p2p-test

I will not paste the code here in order to reduce clutter.

## Compilation

Above errors are produced by `main.cpp` which is slightly modified hip example code. It is compiled with `sbatch build.job` which automatically loads modules and runs: `CC -x hip -o main main.cpp`.

## Used modules

```
Currently Loaded Modules:
  1) cpe/24.11          5) craype-network-ofi        9) cray-mpich/8.1.31
  2) cce/18.0.1         6) cray-libsci/24.11.0      10) libfabric/1.22.0
  3) craype/2.7.33      7) PrgEnv-cray/8.6.0
  4) cray-dsmml/0.3.0   8) craype-accel-amd-gfx90a
```

## Running

The compiled test program can be run with `sbatch run.job`.

It uses one node with two tasks that get one gpu each. I made sure that `--gpus=2` flag is used in order to not run into issues of gpus not seeing each other because of slurm cgroup config with `--gpus-per-task` (https://support.schedmd.com/show_bug.cgi?id=17875).


This means that the script has to manually select the devices using `ROCR_VISIBLE_DEVICES` as recommended by CSC on LUMI (`select_gpu` wrapper script).

`run.job` will run `main` and `main 1`. The first one will MPI send gpu buffer with 10 floats and the second one sends gpu buffer with 1024 floats,
which triggers the error.

## Making sure triggering IPC causes the error

We can force MPI not to use IPC mechanism by setting `export MPICH_GPU_IPC_ENABLED=0`. This is done in `run2.job` which runs `main` and `main 1` without a problem.

# Extra bug

This is not directly related to the above bug but was found during testing and I'm not sure to whom I should report it.

Alongside with `main.cpp` there is `main2.cpp` and `main3.cpp`. They are similar to `main.cpp` with slight modifications. Difference between the two is that `main3.cpp` zeroes out the device buffer which task 0 sends and to which task 1 receives the message. This is done by calling `hipMemset` at the beginning.

This really should not change the result. However, task 1 in `main3.cpp` receives only zeros and not the correct data. To be sure that this is not some optimization related problem `main2.cpp` and `main3.cpp` are compiled with `-O0`.

`main2` and `main3` are build in `build.job` and executed in `run2.job`.
