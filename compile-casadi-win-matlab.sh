set -e

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

rm -rf $HOME/build-casadi-win-matlab
mkdir $HOME/build-casadi-win-matlab

cp CMakeListsWinMatlab.txt $HOME/build-casadi-win-matlab
cp toolchain-casadi.cmake $HOME/build-casadi-win-matlab

cd $HOME/build-casadi-win-matlab

export CC=x86_64-w64-mingw32-gcc-posix
export CXX=x86_64-w64-mingw32-g++-posix

# swig matlab
git clone https://github.com/jaeandersson/swig.git --depth=1
cd swig
./autogen.sh
./configure --prefix=$HOME/build-casadi-win-matlab/swig-install
make -j4
make install

cd ..
rm -r swig

# get ipopt
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
rm -r Ipopt-3.12.3

# setup compiler
export SWIG_HOME=$HOME/build-casadi-win-matlab/swig-matlab-install
export PATH=$SWIG_HOME/bin:$SWIG_HOME/share:$PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$HOME/build-casadi-win-matlab/ipopt-install/lib/pkgconfig

# get matlab
export LDFLAGS=-static-libstdc++

# compile
git clone --branch 3.4.5 https://github.com/casadi/casadi.git --depth=1

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
    -DWITH_EXAMPLES=OFF -DWITH_EXTRA_WARNINGS=ON -DMATLAB_ROOT=$HOME/matlab-install-R2016a ..
make -j4
make install

cd ..
cd ..
rm -r casadi

export datestr=$(date +"%Y%m%d%H%M%")
zip -r casadi-3.4.5-win-matlab-ipopt-minimal-${datestr}.zip casadi-install

cd $HOME
cp $HOME/build-casadi-win-matlab/casadi-3.4.5-win-matlab-ipopt-minimal-${datestr}.zip .
