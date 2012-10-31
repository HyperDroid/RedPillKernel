#!/bin/sh
export KERNELDIR=`readlink -f .`
export RAMFS_SOURCE=`readlink -f $KERNELDIR/../redpill_jb_ramfs_n7100`
export PARENT_DIR=`readlink -f ..`
export CLOUD_DIR="/mnt/hgfs/HyperDroid Note2/RedPill"
export USE_SEC_FIPS_MODE=true
export CROSS_COMPILE=~/Android_Toolchains/Android_Toolchains/arm-eabi-4.4.3/bin/arm-eabi-
export STRIP=~/Android_Toolchains/Android_Toolchains/arm-eabi-4.4.3/bin/arm-eabi-strip

if [ "${1}" != "" ];then
  export KERNELDIR=`readlink -f ${1}`
fi

RAMFS_TMP="/tmp/ramdisk"

if [ ! -f $KERNELDIR/.config ];
then
  make redpill_jb_n7100_defconfig
fi

. $KERNELDIR/.config

export ARCH=arm

cd $KERNELDIR/
nice -n 10 make -j4 || exit 1

#remove previous ramfs files
rm -rf $RAMFS_TMP
rm -rf $RAMFS_TMP.cpio
rm -rf $RAMFS_TMP.cpio.gz
#copy ramfs files to tmp directory
cp -ax $RAMFS_SOURCE $RAMFS_TMP
#clear git repositories in ramfs
find $RAMFS_TMP -name .git -exec rm -rf {} \;
#remove empty directory placeholders
find $RAMFS_TMP -name EMPTY_DIRECTORY -exec rm -rf {} \;
rm -rf $RAMFS_TMP/tmp/*
#remove mercurial repository
rm -rf $RAMFS_TMP/.hg
#copy modules into ramfs
mkdir -p $RAMFS_TMP/lib/modules
find -name '*.ko' -exec cp -av {} $RAMFS_TMP/lib/modules/ \;
$STRIP --strip-unneeded $RAMFS_TMP/lib/modules/*

cd $RAMFS_TMP
find | fakeroot cpio -H newc -o > $RAMFS_TMP.cpio 2>/dev/null
ls -lh $RAMFS_TMP.cpio
gzip -9 $RAMFS_TMP.cpio
cd -

nice -n 10 make -j4 zImage || exit 1

./mkbootimg --kernel $KERNELDIR/arch/arm/boot/zImage --ramdisk $RAMFS_TMP.cpio.gz --board smdk4x12 --base 0x10000000 --pagesize 2048 --ramdiskaddr 0x11000000 -o ./boot.img

TAR_NAME=$KERNELDIR/`echo $CONFIG_LOCALVERSION|cut -c 2-`.tar
ZIP_NAME=$KERNELDIR/`echo $CONFIG_LOCALVERSION|cut -c 2-`_CWM.zip
echo $TAR_NAME
echo $ZIP_NAME

#cd $KERNELDIR
tar cf $TAR_NAME boot.img && ls -lh $TAR_NAME
cd $PARENT_DIR/Releases/CWM-RELEASE
cp $KERNELDIR/boot.img .
rm -f $ZIP_NAME
zip -r $ZIP_NAME *
cd ..

cp $TAR_NAME $PARENT_DIR/Releases
cp $ZIP_NAME $PARENT_DIR/Releases
cp $ZIP_NAME $CLOUD_DIR
rm -f $TAR_NAME
rm -f $ZIP_NAME
