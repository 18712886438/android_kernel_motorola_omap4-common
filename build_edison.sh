#!/bin/bash
set -m

# Build script for JBX-Kernel RELEASE
echo "Cleaning out kernel source directory..."
echo " "
make mrproper

# We build the kernel and its modules first
# Launch execute script in background
# First get tags in shell
echo "Cleaning out Android source directory..."
echo " "
cd /home/dtrail/android/4.3
export USE_CCACHE=1
make mrproper
make ARCH=arm distclean
source build/envsetup.sh
lunch cm_spyder-userdebug

# built kernel & modules
echo "Building kernel and modules..."
echo " "
export LOCALVERSION="-JBX-1.0-Hybrid-Edison"
make -j4 TARGET_BOOTLOADER_BOARD_NAME=edison TARGET_KERNEL_SOURCE=/home/dtrail/android/android_kernel_motorola_omap4-common/ TARGET_KERNEL_CONFIG=mapphone_OCEdison_defconfig BOARD_KERNEL_CMDLINE='root=/dev/ram0 rw mem=1023M@0x80000000 console=null vram=10300K omapfb.vram=0:8256K,1:4K,2:2040K init=/init ip=off mmcparts=mmcblk1:p7(pds),p15(boot),p16(recovery),p17(cdrom),p18(misc),p19(cid),p20(kpanic),p21(system),p22(cache),p23(preinstall),p24(webtop),p25(userdata) mot_sst=1 androidboot.bootloader=0x0A72' $OUT/boot.img

# We don't use the kernel but the modules
echo "Copying modules to package folder"
echo " "
cp -r /home/dtrail/android/4.3/out/target/product/spyder/system/lib/modules/* /home/dtrail/android/built/rls/system/lib/modules/
cp /home/dtrail/android/4.3/out/target/product/spyder/kernel /home/dtrail/android/built/rls/system/etc/kexec/

echo "------------- "
echo "Done building"
echo "------------- "
echo " "

# Copy and rename the zImage into nightly/nightly package folder
# Keep in mind that we assume that the modules were already built and are in place
# So we just copy and rename, then pack to zip including the date
echo "Packaging flashable Zip file..."
echo " "

cd /home/dtrail/android/built/rls
zip -r "JBX-Kernel-1.0-Hybrid-Edison_$(date +"%Y-%m-%d").zip" *
mv "JBX-Kernel-1.0-Hybrid-Edison_$(date +"%Y-%m-%d").zip" /home/dtrail/android/out

# Exporting changelog to file
echo "Exporting changelog to file: '/built/Changelog-[date]'"
echo " "
cd /home/dtrail/android/android_kernel_motorola_omap4-common
git log --oneline --since="4 day ago" > /home/dtrail/android/android_kernel_motorola_omap4-common/changelog/Changelog_$(date +"%Y-%m-%d")
git log --oneline  > /home/dtrail/android/android_kernel_motorola_omap4-common/changelog/Full_History_Changelog
git add changelog/ .
git commit -m "Added todays changelog and updated full history"
git push origin EDISON_4.3

echo "done"
