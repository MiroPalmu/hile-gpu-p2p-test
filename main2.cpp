#include <stdio.h>
#include <hip/hip_runtime.h>
#include <mpi.h>

int main(int argc, char **argv) {
  MPI_Init(&argc,&argv);

  int *d_buf;
  int bufsize;
  if (argc >= 2) {
    bufsize=1024;
  } else {
    bufsize=10;
  }

  hipMalloc(&d_buf, bufsize*sizeof(int));
  // hipMemset(d_buf, 0, bufsize*sizeof(int));

  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  int *h_buf=(int*) malloc(sizeof(int)*bufsize);

  if(rank==0) {
    for(int i=0;i<bufsize;i++)
      h_buf[i]=i;

    hipMemcpy(d_buf, h_buf, bufsize*sizeof(int), hipMemcpyHostToDevice);
    MPI_Send(d_buf, bufsize, MPI_INT, 1, 123, MPI_COMM_WORLD);
  }

  if(rank==1) {
    MPI_Status status;
    MPI_Recv(d_buf, bufsize, MPI_INT, 0, 123, MPI_COMM_WORLD, &status);

    hipMemcpy(h_buf, d_buf, bufsize*sizeof(int), hipMemcpyDeviceToHost);
    for(int i=0;i<bufsize;i++) {
      if(h_buf[i] != i)
        printf("Error: buffer[%d]=%d but expected %d\n", i, h_buf[i], i);
      }
    fflush(stdout);
  }

  //free buffers
  free(h_buf);
  hipFree(d_buf);

  MPI_Finalize();
}
