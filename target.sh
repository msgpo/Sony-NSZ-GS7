#!/bin/sh
# builds debugger and libraries for Sony NSZ-GS7
# should be built on a older OS like Ferdora 14
set -e
export TARGET=arm-linux-gnueabi
export PREFIX=$PWD/cross
export PATH=$PATH:$PREFIX/bin
export TARGET_ROOT=$PWD/target
export TARGET_LIB=$TARGET_ROOT/lib
export TARGET_INC=$TARGET_ROOT/include
export TARGET_BIN=$TARGET_ROOT/bin

rm -fr $PWD/build_termcap
rm -fr $PWD/build_gdb
rm -fr $PWD/build_glibc
rm -fr $PWD/termcap-1.3.1
rm -fr $PWD/gdb-6.6
rm -fr $PWD/glibc-2.12.2
rm -fr $PWD/glibc-ports-2.12.1
rm -fr $PWD/gmp-5.0.1
rm -fr $PWD/mpfr-3.0.0
rm -fr $PWD/target

cd $PWD/linux
rm -fr *
git checkout -f tags/v2.6.35
make ARCH=arm INSTALL_HDR_PATH=$TARGET_ROOT headers_install
sed -i '/1024/a#define SSIZE_MAX   LONG_MAX' \
       $TARGET_INC/linux/limits.h
cd ..

tar xjfv $PWD/gdb-6.6a.tar.bz2
tar xzvf $PWD/termcap-1.3.1.tar.gz
tar xjfv $PWD/glibc-2.12.2.tar.bz2
tar xjfv $PWD/glibc-ports-2.12.1.tar.bz2
tar xjfv $PWD/gmp-5.0.1.tar.bz2
tar xjfv $PWD/mpfr-3.0.0.tar.bz2

mkdir $PWD/build_termcap
mkdir $PWD/build_gdb
mkdir $PWD/build_glibc

cd $PWD/gdb-6.6
ln -s ../gmp-5.0.1 gmp
ln -s ../mpfr-3.0.0 mpfr
ln -s ../termcap-1.3.1 termcap
mkdir ../build_gdb/mpfr
cp gmp/longlong.h ../build_gdb/mpfr
cp gmp/gmp-impl.h ../build_gdb/mpfr
cd ..

cd $PWD/glibc-2.12.2
ln -s ../glibc-ports-2.12.1 ports
cd ..

cd $PWD/build_termcap
export CC=$PREFIX/bin/$TARGET-gcc
export AR=$PREFIX/bin/$TARGET-ar
export RANLIB=$PREFIX/bin/$TARGET-ranlib
../termcap-1.3.1/configure \
    --target=$TARGET \
    --host=$TARGET \
    --build=$MACHTYPE \
    --prefix=$PREFIX/$TARGET
make -j2 all
make DESTDIR=$PREFIX/$TARGET install
cd ..

cd $PWD/build_gdb
../gdb-6.6/configure \
    --target=$TARGET \
    --host=$TARGET \
    --build=$MACHTYPE \
    --disable-nls \
    --prefix= 
make -j2 all
make DESTDIR=$TARGET_ROOT install
cd ..

cd $PWD/build_glibc
../glibc-2.12.2/configure \
    --target=$TARGET \
    --host=$TARGET \
    --build=$MACHTYPE \
    --prefix= \
    --with-headers=$TARGET_INC \
    --enable-kernel=2.6.35 \
    --enable-add-ons=nptl,ports \
    --disable-multilib \
    --disable-nls
make -j2 all
make install_root=$TARGET_ROOT install
cd ..

cp $PREFIX/$TARGET/lib/libgcc* $TARGET_LIB/
cp $PREFIX/$TARGET/lib/libstdc++* $TARGET_LIB/
cp $PREFIX/$TARGET/lib/libsupc++* $TARGET_LIB/
cp $PREFIX/$TARGET/lib/libtermcap.a $TARGET_LIB/

rm -fr $PWD/build_termcap
rm -fr $PWD/build_gdb
rm -fr $PWD/build_glibc
rm -fr $PWD/termcap-1.3.1
rm -fr $PWD/gdb-6.6
rm -fr $PWD/glibc-2.12.2
rm -fr $PWD/glibc-ports-2.12.1
rm -fr $PWD/gmp-5.0.1
rm -fr $PWD/mpfr-3.0.0

echo Done!


