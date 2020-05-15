#!/bin/sh
#
# builds cross compiler debugger and libraries for Sony NSZ-GS7
# should be built on a older OS like Ferdora 14
#
set -e
export TARGET=arm-linux-gnueabi
export PREFIX=$PWD/cross
export PATH=$PATH:$PREFIX/bin
rm -fr $PREFIX
mkdir $PREFIX
mkdir $PREFIX/etc
touch $PREFIX/etc/ld.so.conf
mkdir $PREFIX/$TARGET
mkdir $PREFIX/$TARGET/lib
touch $PREFIX/$TARGET/lib/crti.o
touch $PREFIX/$TARGET/lib/crtn.o
touch $PREFIX/$TARGET/lib/libc.so

rm -fr $PWD/build_binutils
rm -fr $PWD/build_gcc
rm -fr $PWD/build_gdb
rm -fr $PWD/build_glibc
rm -fr $PWD/build_termcap
rm -fr $PWD/binutils-2.27
rm -fr $PWD/gdb-6.6
rm -fr $PWD/glibc-2.12.2
rm -fr $PWD/gcc-4.4.5
rm -fr $PWD/gmp-5.0.1
rm -fr $PWD/mpfr-3.0.0
rm -fr $PWD/glibc-ports-2.12.1
rm -fr $PWD/termcap-1.3.1

if [ ! -f $PWD/binutils-2.27.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/binutils/binutils-2.27.tar.bz2
fi

if [ ! -f $PWD/gdb-6.6a.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/gdb/gdb-6.6a.tar.bz2
fi

if [ ! -f $PWD/glibc-2.12.2.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/glibc/glibc-2.12.2.tar.bz2
fi

if [ ! -f $PWD/gcc-4.4.5.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/gcc/gcc-4.4.5/gcc-4.4.5.tar.bz2
fi
 
if [ ! -f $PWD/gmp-5.0.1.tar.bz2 ]; then
    wget http://ftp.gnu.org/pub/gnu/gmp/gmp-5.0.1.tar.bz2
fi

if [ ! -f $PWD/mpfr-3.0.0.tar.bz2 ]; then
    wget http://ftp.gnu.org/pub/gnu/mpfr/mpfr-3.0.0.tar.bz2
fi

if [ ! -f $PWD/glibc-ports-2.12.1.tar.bz2 ]; then
    wget http://ftp.gnu.org/pub/gnu/glibc/glibc-ports-2.12.1.tar.bz2
fi

if [ ! -f $PWD/termcap-1.3.1.tar.gz ]; then
    wget http://ftp.gnu.org/pub/gnu/termcap/termcap-1.3.1.tar.gz
fi

if [ ! -d $PWD/linux ]; then
    git clone git://github.com/torvalds/linux.git
fi

tar xjfv $PWD/binutils-2.27.tar.bz2
tar xjfv $PWD/gdb-6.6a.tar.bz2
tar xjfv $PWD/glibc-2.12.2.tar.bz2
tar xjfv $PWD/gcc-4.4.5.tar.bz2
tar xjfv $PWD/gmp-5.0.1.tar.bz2
tar xjfv $PWD/mpfr-3.0.0.tar.bz2
tar xjfv $PWD/glibc-ports-2.12.1.tar.bz2
tar xzvf $PWD/termcap-1.3.1.tar.gz

cd $PWD/linux
rm -fr *
git checkout -f tags/v2.6.35
make ARCH=arm INSTALL_HDR_PATH=$PREFIX/$TARGET headers_install
sed -i '/1024/a#define SSIZE_MAX   LONG_MAX' \
       $PREFIX/$TARGET/include/linux/limits.h 
cd ..

mkdir $PWD/build_binutils
mkdir $PWD/build_gcc
mkdir $PWD/build_gdb
mkdir $PWD/build_glibc
mkdir $PWD/build_termcap

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

cd $PWD/build_binutils
../binutils-2.27/configure \
    --target=$TARGET \
    --host=$MARCHTYPE \
    --build=$MACHTYPE \
    --prefix=$PREFIX \
    --disable-nls
make -j2 all
make install
cd ..

cd $PWD/build_gcc
../gcc-4.4.5/configure \
    --target=$TARGET \
    --host=$MACHTYPE \
    --build=$MACHTYPE \
    --prefix=$PREFIX \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-nls \
    --disable-threads
make -j2 all-gcc
make install-gcc
cd ..

cd $PWD/build_glibc
../glibc-2.12.2/configure \
    --target=$TARGET \
    --host=$TARGET \
    --build=$MACHTYPE \
    --prefix=$PREFIX/$TARGET \
    --with-headers=$PREFIX/$TARGET/include \
    --disable-multilib \
    --enable-kernel=2.6.35 \
    --disable-nls \
    --disable-threads \
    --enable-add-ons=nptl,ports \
    libc_cv_forced_unwind=yes \
    libc_cv_c_cleanup=yes
make install-bootstrap-headers=yes install-headers
make -j2 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/$TARGET/lib
$TARGET-gcc -nostdlib -nostartfiles -shared -x c /dev/null \
    -o $PREFIX/$TARGET/lib/libc.so
touch $PREFIX/$TARGET/include/gnu/stubs.h
cd ..

rm -fr $PWD/build_gcc
mkdir $PWD/build_gcc
mkdir $PWD/build_gcc/mpfr
cp gmp-5.0.1/longlong.h build_gcc/mpfr
cp gmp-5.0.1/gmp-impl.h build_gcc/mpfr
cd $PWD/build_gcc
../gcc-4.4.5/configure \
    --target=$TARGET \
    --host=$MARCHTYPE \
    --build=$MACHTYPE \
    --prefix=$PREFIX \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-nls
make -j2 all-gcc
make install-gcc
make -j2 all-target-libgcc
make install-target-libgcc
cd ..

rm -fr $PWD/build_glibc
mkdir $PWD/build_glibc
cd $PWD/build_glibc
../glibc-2.12.2/configure \
    --target=$TARGET \
    --host=$TARGET \
    --build=$MACHTYPE \
    --prefix=$PREFIX/$TARGET \
    --with-headers=$PREFIX/$TARGET/include \
    --disable-multilib \
    --enable-kernel=2.6.35 \
    --disable-nls \
    --enable-add-ons=nptl,ports \
    libc_cv_forced_unwind=yes \
    libc_cv_c_cleanup=yes
make -j2
make install
cd ..

cd $PWD/build_gcc
make -j2
make install
cd ..

cd $PWD/build_gdb
../gdb-6.6/configure \
    --target=$TARGET \
    --host=$MARCHTYPE \
    --build=$MARCHTYPE \
    --prefix=$PREFIX \
    --disable-nls
make -j2 all
make install
cd ..

rm -fr $PWD/build_binutils
rm -fr $PWD/build_gcc
rm -fr $PWD/build_gdb
rm -fr $PWD/build_glibc
rm -fr $PWD/build_termcap
rm -fr $PWD/binutils-2.27
rm -fr $PWD/gdb-6.6
rm -fr $PWD/glibc-2.12.2
rm -fr $PWD/gcc-4.4.5
rm -fr $PWD/gmp-5.0.1
rm -fr $PWD/mpfr-3.0.0
rm -fr $PWD/glibc-ports-2.12.1
rm -fr $PWD/termcap-1.3.1

echo Done!


