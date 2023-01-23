# ff-bifbox
Numerical bifurcation analysis toolbox in FreeFEM

# FREEFEM INSTALL INSTRUCTIONS (USE AT OWN RISK)

# First make sure you have a working MPI implementation

cd TO/YOUR/PREFERRED/INSTALL/DIRECTORY/

export FF_DIR=${PWD}/FreeFem-sources

export PETSC_DIR=${PWD}/petsc

export PETSC_ARCH=arch-FreeFem

export PETSC_VAR=${PETSC_DIR}/${PETSC_ARCH}

# Clone repos

git clone https://github.com/FreeFem/FreeFem-sources

git clone https://gitlab.com/petsc/petsc

#Compile real PETSc

cd ${PETSC_DIR} && ./configure --download-mumps --download-parmetis --download-metis --download-hypre --download-superlu --download-slepc --download-hpddm --download-ptscotch --download-suitesparse --download-scalapack --download-tetgen --download-mmg --download-parmmg --with-fortran-bindings=no --with-scalar-type=real --with-debugging=no

make

#Compile complex PETSc

export PETSC_ARCH=arch-FreeFem-complex

./configure --with-mumps-dir=arch-FreeFem --with-parmetis-dir=arch-FreeFem --with-metis-dir=arch-FreeFem --with-superlu-dir=arch-FreeFem --download-slepc --download-hpddm --download-htool --with-ptscotch-dir=arch-FreeFem --with-suitesparse-dir=arch-FreeFem --with-scalapack-dir=arch-FreeFem --with-tetgen-dir=arch-FreeFem --with-fortran-bindings=no --with-scalar-type=complex --with-debugging=no

make

# Compile FreeFEM

cd ${FF_DIR}

git checkout petsc-v3.19.0

autoreconf -i

./configure --without-hdf5 --with-petsc=${PETSC_VAR}/lib --with-petsc_complex=${PETSC_VAR}-complex/lib

make -j4

# Add FreeFEM to your path. To do this, I paste the following lines in my .bashrc file.

export PATH="$HOME/.local/bin:$HOME/.local/FreeFem-sources/src/mpi:$HOME/.local/FreeFem-sources/src/nw:$PATH"

export FF_INCLUDEPATH="$HOME/.local/FreeFem-sources/idp"

export FF_LOADPATH="$HOME/.local/FreeFem-sources/plugin/mpi;;$HOME/.local/FreeFem-sources/plugin/seq"

#end
