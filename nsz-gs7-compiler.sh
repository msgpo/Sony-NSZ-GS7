#!/bin/sh
# builds compiler debugger and libraries or Sony NSZ-GS7
# should be built on a older OS like Ferdora 7
set -e
export TARGET=arm-linux-gnueabi
export PREFIX=$PWD/arm_cross
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

rm -fr build_binutils
rm -fr build_gcc
rm -fr build_gdb
rm -fr build_gdbserver
rm -fr build_glibc
rm -fr binutils-2.25
rm -fr gdb-6.6
rm -fr glibc-2.12.2
rm -fr gcc-4.4.5
rm -fr gmp-5.0.1
rm -fr mpfr-3.0.0
rm -fr glibc-ports-2.12.1


if [ ! -f binutils-2.25.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/binutils/binutils-2.25.tar.bz2
fi

if [ ! -f gdb-6.6a.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/gdb/gdb-6.6a.tar.bz2
fi

if [ ! -f glibc-2.12.2.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/glibc/glibc-2.12.2.tar.bz2
fi

if [ ! -f gcc-4.4.5.tar.bz2 ]; then
    wget http://ftp.gnu.org/gnu/gcc/gcc-4.4.5/gcc-4.4.5.tar.bz2
fi
 
if [ ! -f gmp-5.0.1.tar.bz2 ]; then
    wget http://ftp.gnu.org/pub/gnu/gmp/gmp-5.0.1.tar.bz2
fi

if [ ! -f mpfr-3.0.0.tar.bz2 ]; then
    wget http://ftp.gnu.org/pub/gnu/mpfr/mpfr-3.0.0.tar.bz2
fi

if [ ! -f glibc-ports-2.12.1.tar.bz2 ]; then
    wget http://ftp.gnu.org/pub/gnu/glibc/glibc-ports-2.12.1.tar.bz2
fi

if [ ! -d linux ]; then
    git clone git://github.com/torvalds/linux.git
fi

tar xjfv binutils-2.25.tar.bz2
tar xjfv gdb-6.6a.tar.bz2
tar xjfv glibc-2.12.2.tar.bz2
tar xjfv gcc-4.4.5.tar.bz2
tar xjfv gmp-5.0.1.tar.bz2
tar xjfv mpfr-3.0.0.tar.bz2
tar xjfv glibc-ports-2.12.1.tar.bz2

cd linux
git checkout -f tags/v2.6.35
make ARCH=arm INSTALL_HDR_PATH=$PREFIX/$TARGET headers_install
cd ..

mkdir build_binutils
mkdir build_gcc
mkdir build_gdb
mkdir build_gdbserver
mkdir build_glibc

cd gcc-4.4.5
ln -s ../gmp-5.0.1 gmp
ln -s ../mpfr-3.0.0 mpfr
mkdir ../build_gcc/mpfr
cp gmp/longlong.h ../build_gcc/mpfr
cp gmp/gmp-impl.h ../build_gcc/mpfr
cd ..

cd binutils-2.25
ln -s ../gmp-5.0.1 gmp
ln -s ../mpfr-3.0.0 mpfr
mkdir ../build_binutils/mpfr
cp gmp/longlong.h ../build_binutils/mpfr
cp gmp/gmp-impl.h ../build_binutils/mpfr
cd ..

cd gdb-6.6
ln -s ../gmp-5.0.1 gmp
ln -s ../mpfr-3.0.0 mpfr
mkdir ../build_gdb/mpfr
cp gmp/longlong.h ../build_gdb/mpfr
cp gmp/gmp-impl.h ../build_gdb/mpfr
cd ..

cd glibc-2.12.2
ln -s ../glibc-ports-2.12.1 ports
cd ..

cd build_binutils
../binutils-2.25/configure \
    --target=$TARGET \
    --prefix=$PREFIX \
    --disable-multilib \
    --disable-nls
make -j2 all
make install
cd ..

cd build_gcc
../gcc-4.4.5/configure \
    --target=$TARGET \
    --prefix=$PREFIX \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-nls \
    --disable-threads
make -j2 all-gcc
make install-gcc
cd ..

cd build_glibc
../glibc-2.12.2/configure \
    --prefix=$PREFIX/$TARGET \
    --host=$TARGET \
    --target=$TARGET \
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

rm -fr build_gcc
mkdir build_gcc
mkdir build_gcc/mpfr
cp gmp-5.0.1/longlong.h build_gcc/mpfr
cp gmp-5.0.1/gmp-impl.h build_gcc/mpfr
cd build_gcc
../gcc-4.4.5/configure \
    --target=$TARGET \
    --prefix=$PREFIX \
    --enable-languages=c,c++ \
    --disable-multilib \
    --disable-nls
make -j2 all-gcc
make install-gcc
make -j2 all-target-libgcc
make install-target-libgcc
cd ..

rm -fr build_glibc
mkdir build_glibc
cd build_glibc
../glibc-2.12.2/configure \
    --prefix=$PREFIX/$TARGET \
    --build=$MACHTYPE \
    --host=$TARGET \
    --target=$TARGET \
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

cd build_gcc
make -j2
make install
cd ..

cd build_gdb
../gdb-6.6/configure \
    --target=$TARGET \
    --prefix=$PREFIX
make -j2 all
make install
cd ..

cd build_gdbserver
../gdb-6.6/gdb/gdbserver/configure \
    --target=$TARGET \
    --host=$TARGET \
    --prefix=
make -j2 all
make DESTDIR=$PREFIX/target install
cd ..

rm -fr build_glibc
mkdir build_glibc
cd build_glibc
../glibc-2.12.2/configure \
    --prefix= \
    --build=$MACHTYPE \
    --host=$TARGET \
    --target=$TARGET \
    --with-headers=$PREFIX/$TARGET/include \
    --disable-multilib \
    --enable-kernel=2.6.35 \
    --enable-add-ons=nptl,ports \
    --disable-nls
make -j2 all
make install_root=$PREFIX/target install
cd ..

cp $PREFIX/$TARGET/lib/libgcc* $PREFIX/target/lib/
cp $PREFIX/$TARGET/lib/libstdc++* $PREFIX/target/lib/
cp $PREFIX/$TARGET/lib/libsupc++* $PREFIX/target/lib/

rm -fr build_binutils
rm -fr build_gcc
rm -fr build_gdb
rm -fr build_gdbserver
rm -fr build_glibc
rm -fr binutils-2.25
rm -fr gdb-6.6
rm -fr glibc-2.12.2
rm -fr gcc-4.4.5
rm -fr gmp-5.0.1
rm -fr mpfr-3.0.0
rm -fr glibc-ports-2.12.1

