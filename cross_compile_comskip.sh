#!/usr/bin/env bash
# Copyright RBoy, licensed under GPL version 3
# set -x

echo "Starting building of Comskip components..."

echo "Building ffmpeg, this may take about 4GB of free space"
if [[ ! -d patches || ! -f cross_compile_ffmpeg.sh ]]; then
  echo "ERROR: Cannot find ffmpeg build script files"
  exit 1
fi
unset CFLAGS
unset LDFLAGS
unset PKG_CONFIG_PATH
./cross_compile_ffmpeg.sh --disable-nonfree=y --build-intel-qsv=y --build-amd-amf=y --compiler-flavors=multi --git-get-latest=n || exit 1

build_argtable() {
echo "Building Argtable2"
unset CFLAGS
unset LDFLAGS
unset PKG_CONFIG_PATH
wget https://downloads.sourceforge.net/project/argtable/argtable/argtable-2.13/argtable2-13.tar.gz || exit 1
tar -xf argtable2-13.tar.gz || exit 1
rm argtable2-13.tar.gz
cd argtable2-13
export CFLAGS="-I../${cc_path}/$1/include"
./configure --host=$1 --prefix=$PWD/../${cc_path}/$1 || exit 1
make CC=$PWD/../${cc_path}/bin/$1-gcc AR=$PWD/../${cc_path}/bin/$1-ar PREFIX=$PWD/../${cc_path}/$1 RANLIB=$PWD/../${cc_path}/bin/$1-ranlib LD=$PWD/../${cc_path}/bin/$1-ld STRIP=$PWD/../${cc_path}/bin/$1-strip CXX=$PWD/../${cc_path}/bin/$1-g++ || exit 1
cd ..
}


build_comskip() {
echo "Building Comskip"
unset CFLAGS
unset LDFLAGS
unset PKG_CONFIG_PATH
org_path=$PATH # Save the current path
export PATH="$PWD/sandbox/$1/bin:$PATH"
export PKG_CONFIG_PATH="./${cc_path}/$1/lib/pkgconfig:./argtable2-13"
export CFLAGS="-I./${cc_path}/$1/include -I./argtable2-13/src"
export LDFLAGS="-L./${cc_path}/$1/lib -L./argtable2-13/src/.libs"
./autogen.sh || exit 1
./configure --host=$1 --prefix=$PWD/${cc_path}/$1 || exit 1
make clean
make CC=$PWD/${cc_path}/bin/$1-gcc AR=$PWD/${cc_path}/bin/$1-ar PREFIX=$PWD/${cc_path}/$1 RANLIB=$PWD/${cc_path}/bin/$1-ranlib LD=$PWD/${cc_path}/bin/$1-ld STRIP=$PWD/${cc_path}/bin/$1-strip CXX=$PWD/${cc_path}/bin/$1-g++ comskip || exit 1
./${cc_path}/bin/$1-strip -s comskip || exit 1
export PATH=$org_path # Restore original path
mv comskip comskip-$2.exe # rename it to something Windows can use
if [[ ! -f comskip-$2.exe ]]; then
  echo "ERROR: Comskip did not build"
  exit 1
else
  echo "Comskip-$2.exe was built successfully!!"
fi
}

cc_path="sandbox/cross_compilers/mingw-w64-i686"
build_argtable i686-w64-mingw32
build_comskip i686-w64-mingw32 x86
rm -r argtable2-13

cc_path="sandbox/cross_compilers/mingw-w64-x86_64"
build_argtable x86_64-w64-mingw32
build_comskip x86_64-w64-mingw32 x64
rm -r argtable2-13
