# QuantumESPRESSO

Manual build.

module load PrgEnv-gnu/8.1.0
module load cray-fftw/3.3.8.11

./configure F90=ftn MPIF90=ftn CC=cc BLAS_LIBS="-L/opt/cray/pe/libsci/21.08.1.2/GNU/9.1/x86_64/lib -llibsci_gnu_mp" LAPACK_LIBS="-L/opt/cray/pe/libsci/21.08.1.2/GNU/9.1/x86_64/lib -llibsci_gnu_mp" SCALAPACK_LIBS="-L/opt/cray/pe/libsci/21.08.1.2/GNU/9.1/x86_64/lib -llibsci_gnu_mp" FFTW_INCLUDE=$FFTW_INC FFT_LIBS="-L$FFTW_DIR -lfftw3" --enable-parallel --enable-openmp --with-scalapack



