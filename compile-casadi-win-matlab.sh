# This build script compiles Ipopt and CasADi for Windows (64bit) using MinGW.
#
# Many features of CasADi will not be included. Only the following packages
# and interfaces are included:
#   - Ipopt
#     - Metis
#     - Blas
#     - Lapack
#     - Mumps
#   - CasADi
#     - Matlab interface
#     - OpenMP
#     - Ipopt interface
#
# SWIG is used to create the Matlab interface but the library is not included
# in the final archive.
#
# The script remember when it completes step by dropping files in the build
# directory. You can enforce recompilation by removing the _COMPLETE files or
# deleting the whole build directory.
#
# The build directory will be created in the home directory with the name
# build-casadi-linux-matlab.
#
# To be able to use MinGW to compile casadi we need to replace a CMakeLists file
# for the SWIG interface and we need to provide a toolchain file for cmake that
# sets up the x86_64-w64-mingw32-gcc-posix compiler.
#
# Original source: https://github.com/OpenOCL/ocl-deployment/
# MIT License
#
# Author: Jonas Koenemann
set -e

if [ -z "${MATLAB_ROOT}" ]; then
   echo "You need to set MATLAB_ROOT environment variable to directory of your Matlab installation."
   exit 1
fi

if [ ! -e "$HOME/build-casadi-win-matlab" ]; then
  mkdir $HOME/build-casadi-win-matlab
fi

# copy patches to the build directory
cp CMakeListsWinMatlab.txt $HOME/build-casadi-win-matlab
cp toolchain-casadi.cmake $HOME/build-casadi-win-matlab

cd $HOME/build-casadi-win-matlab

if [ ! -f "APT_COMPLETE" ]; then

  sudo apt-get update -qq
  sudo apt-get install p7zip-full -y
  sudo apt-get install bison -y
  sudo apt-get install -y binutils gcc g++ gfortran git cmake liblapack-dev ipython
  sudo apt-get install -y python-dev python-numpy python-scipy python-matplotlib
  sudo apt-get install -y libmumps-seq-dev libblas-dev liblapack-dev libxml2-dev
  sudo apt-get install -y fakeroot rpm alien
  sudo apt-get install -y libpcre3-dev automake yodl
  sudo apt-get install -y dpkg
  sudo apt-get install -y mingw-w64 g++-mingw-w64 gcc-mingw-w64 gfortran-mingw-w64 mingw-w64-tools

  touch APT_COMPLETE

fi # APT_COMPLETE

if [ ! -f "SWIG_COMPLETE" ]; then

  rm -rf $HOME/build-casadi-win-matlab/swig-install
  rm -rf swig

  # swig matlab w pcre
  git clone https://github.com/jaeandersson/swig.git --depth=1
  cd swig
  wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.42.tar.gz
  sh Tools/pcre-build.sh --host=x86_64 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++
  ./autogen.sh
  ./configure --prefix=$HOME/build-casadi-win-matlab/swig-install \
      --host=x86_64 CC=x86_64-w64-mingw32-gcc CXX=x86_64-w64-mingw32-g++
  make -j4
  make install

  cd ..

  touch SWIG_COMPLETE

fi # SWIG_COMPLETE

if [ ! -f "IPOPT_COMPLETE" ]; then

  rm -rf $HOME/build-casadi-win-matlab/ipopt-install
  rm -rf Ipopt-3.12.3

  wget http://www.coin-or.org/download/source/Ipopt/Ipopt-3.12.3.tgz
  tar -xf Ipopt-3.12.3.tgz
  cd Ipopt-3.12.3
  cd ThirdParty

  cd Metis
  ./get.Metis
  cd ..

  cd Blas
  ./get.Blas
  cd ..

  cd Lapack
  ./get.Lapack
  cd ..

  cd Mumps
  ./get.Mumps
  cd ..

  cd ..

  mkdir build
  cd build
  mkdir $HOME/build-casadi-win-matlab/ipopt-install
  ../configure --prefix=$HOME/build-casadi-win-matlab/ipopt-install --host x86_64-w64-mingw32 \
      --enable-dependency-linking --build mingw32 --disable-shared ADD_FFLAGS=-fPIC ADD_CFLAGS=-fPIC ADD_CXXFLAGS=-fPIC \
      --with-blas=BUILD --with-lapack=BUILD --with-mumps=BUILD --with-metis=BUILD --without-hsl --without-asl
  make -j4
  make install
  cd ..
  cd ..

  rm Ipopt-3.12.3.tgz

  touch IPOPT_COMPLETE

fi # IPOPT_COMPLETE

if [ ! -f "CASADI_COMPLETE" ]; then

  rm -rf $HOME/build-casadi-win-matlab/casadi-install
  rm -rf casadi

  export SWIG_HOME="$HOME/build-casadi-win-matlab/swig-install"
  export PATH="$SWIG_HOME/bin:$SWIG_HOME/share:$PATH"
  export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$HOME/build-casadi-win-matlab/ipopt-install/lib/pkgconfig"

  export LDFLAGS=-static-libstdc++

  git clone https://github.com/casadi/casadi.git --depth=1

  # copy CMakeLists patch
  mv casadi/swig/matlab/CMakeLists.txt casadi/swig/matlab/CMakeLists_bkp.txt
  cp CMakeListsWinMatlab.txt casadi/swig/matlab/CMakeLists.txt

  cd casadi
  mkdir build
  cp ../toolchain-casadi.cmake .
  cd build
  cmake -DCMAKE_INSTALL_PREFIX=$HOME/build-casadi-win-matlab/casadi-install -DMATLAB_EXTRA_CXXFLAGS=\"-D__STDC_UTF_16__\"  \
      -DCMAKE_TOOLCHAIN_FILE=../toolchain-casadi.cmake -DWITH_OSQP=OFF -DWITH_THREAD_MINGW=OFF \
      -DWITH_THREAD=ON -DWITH_AMPL=OFF -DCMAKE_BUILD_TYPE=Release -DWITH_SO_VERSION=OFF \
      -DWITH_NO_QPOASES_BANNER=ON -DWITH_COMMON=ON -DWITH_HPMPC=OFF -DWITH_BUILD_HPMPC=OFF \
      -DWITH_BLASFEO=OFF -DWITH_BUILD_BLASFEO=OFF -DINSTALL_INTERNAL_HEADERS=ON -DWITH_IPOPT=ON \
      -DWITH_OPENMP=ON -DWITH_SELFCONTAINED=ON -DWITH_DEEPBIND=ON -DWITH_MATLAB=ON -DWITH_DOC=OFF \
      -DWITH_EXAMPLES=OFF -DWITH_EXTRA_WARNINGS=ON -DMATLAB_ROOT=${MATLAB_ROOT} ..
  make -j4
  make install

  cd ..
  cd ..

  touch CASADI_COMPLETE
fi # CASADI_COMPLETE


export datestr=$(date +"%Y%m%d%H%M%")
zip -r casadi-3.4.5-win-matlab-ipopt-minimal-${datestr}.zip casadi-install

cd $HOME
cp $HOME/build-casadi-win-matlab/casadi-3.4.5-win-matlab-ipopt-minimal-${datestr}.zip .
