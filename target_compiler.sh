#!/bin/sh
# builds compiler for Sony NSZ-GS7
# should be built on a older OS like Ferdora 14
set -e
export TARGET=arm-linux-gnueabi
export PREFIX=$PWD/cross
export PATH=$PATH:$PREFIX/bin
export TARGET_ROOT=$PWD/target
export TARGET_LIB=$TARGET_ROOT/lib
export TARGET_INC=$TARGET_ROOT/include
export TARGET_BIN=$TARGET_ROOT/bin

rm -fr $PWD/build_binutils
rm -fr $PWD/build_gcc
rm -fr $PWD/binutils-2.27
rm -fr $PWD/gcc-4.4.5
rm -fr $PWD/gmp-5.0.1
rm -fr $PWD/mpfr-3.0.0

tar xjfv $PWD/binutils-2.27.tar.bz2
tar xjfv $PWD/gcc-4.4.5.tar.bz2
tar xjfv $PWD/gmp-5.0.1.tar.bz2
tar xjfv $PWD/mpfr-3.0.0.tar.bz2

mkdir $PWD/build_binutils
mkdir $PWD/build_gcc

cd $PWD/gcc-4.4.5
ln -s ../gmp-5.0.1 gmp
ln -s ../mpfr-3.0.0 mpfr
mkdir ../build_gcc/mpfr
cp gmp/longlong.h ../build_gcc/mpfr
cp gmp/gmp-impl.h ../build_gcc/mpfr
cd ..

cd $PWD/binutils-2.27
ln -s ../gmp-5.0.1 gmp
ln -s ../mpfr-3.0.0 mpfr
mkdir ../build_binutils/mpfr
cp gmp/longlong.h ../build_binutils/mpfr
cp gmp/gmp-impl.h ../build_binutils/mpfr
cd ..

cd $PWD/build_binutils
../binutils-2.27/configure \
    --target=$TARGET \
    --host=$TARGET \
    --build=$MARCHTYPE \
    --prefix= \
    --disable-nls
make -j2 all
make DESTDIR=$TARGET_ROOT install
cd ..

cd $PWD/build_gcc
../gcc-4.4.5/configure \
    --target=$TARGET \
    --host=$TARGET \
    --build=$MARCHTYPE \
    --prefix= \
    --disable-multilib \
    --disable-nls \
    --enable-languages=c,c++
make -j2 all-gcc
make DESTDIR=$TARGET_ROOT install-gcc
make -j2 all-target-libgcc
make DESTDIR=$TARGET_ROOT install-target-libgcc
cd ..

rm -fr $PWD/build_binutils
rm -fr $PWD/build_gcc
rm -fr $PWD/binutils-2.27
rm -fr $PWD/gcc-4.4.5
rm -fr $PWD/gmp-5.0.1
rm -fr $PWD/mpfr-3.0.0

echo Done!


