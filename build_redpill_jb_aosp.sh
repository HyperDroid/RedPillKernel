#!/bin/sh
export KERNELDIR="/Volumes/HyperDroidModWorkspace/RedPill/RedPill_JB_Kernel_N7100/redpill_jb_kernel_n7100"
export RAMFS_SOURCE="/Volumes/HyperDroidModWorkspace/RedPill/RedPill_JB_Kernel_N7100/cm10_ramfs"
export PARENT_DIR="/Volumes/HyperDroidModWorkspace/RedPill/RedPill_JB_Kernel_N7100"
export CLOUD_DIR="/Users/sarcastillo/Dropbox/HyperDroidNote2/RedPill"
export USE_SEC_FIPS_MODE=true
export CROSS_COMPILE=/Volumes/HyperDroidModWorkspace/HyperDroid/prebuilts/gcc/darwin-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-
export STRIP=/Volumes/HyperDroidModWorkspace/HyperDroid/prebuilts/gcc/darwin-x86/arm/arm-linux-androideabi-4.6/bin/arm-linux-androideabi-strip
export USE_CCACHE=1
export CCACHE_DIR=/Volumes/HyperDroidModWorkspace/tmp/.ccache

if [ "${1}" != "" ];then
  export KERNELDIR=`readlink -f ${1}`
fi

RAMFS_TMP="/Volumes/HyperDroidModWorkspace/tmp/ramdisk"

if [ ! -f $KERNELDIR/.config ];
then
  make redpill_jb_n7100_defconfig_aosp
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
#remove "trash"
#find $RAMFS_TMP -name .DS_Store -exec rm -f {} \;
find $RAMFS_TMP -name \.DS_Store -exec rm -f {} \;
find $RAMFS_TMP -name .gitignore -exec rm -f {} \;
#build cpio
find | cpio -H newc -o > $RAMFS_TMP.cpio 2>/dev/null
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
rm -f $KERNELDIR/boot.img
