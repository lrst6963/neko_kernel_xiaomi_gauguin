#!/bin/bash
## Copy this script inside the kernel directory


# 	0     0                         0    0
# 	00    0 000000 0    0  0000     0   0  000000 00000  0    0 000000 0
# 	0 0   0 0      0   0  0    0    0  0   0      0    0 00   0 0      0
# 	0  0  0 00000  0000   0    0    000    00000  0    0 0 0  0 00000  0
# 	0   0 0 0      0  0   0    0    0  0   0      00000  0  0 0 0      0
# 	0    00 0      0   0  0    0    0   0  0      0   0  0   00 0      0
# 	0     0 000000 0    0  0000     0    0 000000 0    0 0    0 000000 000000
banner="
                          gauguin(Redmi Note9 Pro 5G and XiaoMi 10T Lite) Linux Kernel
"

pause(){
    get_char() {
        SAVEDSTTY=$(stty -g)
        stty -echo
        stty raw
        dd if=/dev/tty bs=1 count=1 2>/dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }

    if [ -z "$1" ]; then
        echo 'Press any key to continue...'
    else
        echo -e "$1"
    fi
    get_char
}

blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
green='\033[32m'
een='\033[0m'

MUX=12
#$(nproc --all)
TARGET_NAME="NekoKernel-gauguin"
KERNEL_DEFCONFIG=vendor/gauguin_user_defconfig
DIR=`readlink -f .`
MAIN=`readlink -f ${DIR}/..`
export PATH="$MAIN/clang-crepuscular/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_COMPILER_STRING="$($MAIN/clang-crepuscular/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

if ! [ -d "$MAIN/clang-crepuscular" ]; then
	echo " clang not found! Cloning..."
	exit 1
fi

KERNEL_DIR=`pwd`
ZIMAGE_DIR="$KERNEL_DIR/out/arch/arm64/boot"
# Speed up build process
#MAKE="./makeparallel"



make_config(){
	echo -e "$cyan**** Kernel defconfig is set to $KERNEL_DEFCONFIG ****$een"
	make ARCH=$ARCH ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- $KERNEL_DEFCONFIG O=out CC=clang
# 	make menuconfig O=out
# 	echo 'CONFIG_KPROBES=y
# 	CONFIG_KPROBE_EVENTS=y
# 	' >> $DIR/out/.config
# 	nvim $DIR/out/.config
# 	cat $DIR/out/.config
}

make_kernel(){
	START_TIME=$(date "+%s")
	echo -e "$blue***********************************************"
	echo "          BUILDING KERNEL          "
	echo -e "***********************************************$een"
	make -j$MUX O=out ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- LLVM=1 LLVM_IAS=1
}

make_clean(){
	echo "Clean source tree and build files..."
	make mrproper
	make clean
	rm -rf $DIR/out
}
make_target(){
	timeout 60 wget "https://github.com/lrst6963/anykernel/raw/main/anykernel.zip" -qO anykernel.zip
	if [ $? != 0 ];then echo -e "$red ERROR: download anykernel.zip timeout  $een" && exit 0;fi
	unzip -oq anykernel.zip
	TIME="$(date "+%Y%m%d-%H%M%S")"
	mkdir -p tmp
	gzip -q $ZIMAGE_DIR/Image
	cp -fp $ZIMAGE_DIR/Image* tmp
	cp -fp $ZIMAGE_DIR/dtbo.img tmp
	find $ZIMAGE_DIR/dts/vendor/qcom -name '*.dtb' -exec cat {} + > $ZIMAGE_DIR/dtb;
	cp -fp $ZIMAGE_DIR/dtb tmp
	cp -rp ./anykernel/* tmp
	cd tmp
	echo $banner > banner
	7za a -mx9 tmp.zip *
	cd ..
	rm *.zip
	ZIP_NAME="$TARGET_NAME-$TIME.zip"
	cp -fp tmp/tmp.zip $ZIP_NAME
	echo -e "$green Save Target File To:  $DIR/$ZIP_NAME $een"
	rm -rf tmp
}



opt(){
	echo $banner
	echo -e "

$green		1.$een Make defconfig( Only build kernel defconfig)

$green		2.$een All(Perform a build without cleaning)

$green		3.$een Cleanbuild(Clean the source tree and build files then perform a all build)

$green		4.$een Flashable(Only generate the flashable zip file. Dont use it before you have built once)

$green		5.$een EXIT(stop this script)

	"
	echo -e "$blue Input Options: $een\c"
		    read oopt
		    case $oopt in
		        "1")
		            make_config
		            pause
		            ;;
		        "2")
#					make_clean
					make_config
					make_kernel
					if [ "$?"=="0" ];then
						echo -e "\n$green Kernel build done $een\n Time:$yellow $(expr $(date "+%s") - $START_TIME)s $een"
						make_target
						echo -e "\e[32mBUILD DONE!\e[0m"
					else
						echo -e "$red Build Failed!\e[0m"
					fi
					pause
		            ;;
		        "3")
		            make_clean
		            pause
		            ;;
		        "4")
					make_clean
		            pause
		            ;;
		        "5")
					exit 0
		            ;;
		        *)
		            echo -e "$red Input ERROR!$een"
		            ;;
		    esac
}

if [ $UID -ne 0 ];then
	while true
	do
	 opt
	done
else
	echo -e "

	$red Please do not use ROOT users! Please replace ordinary users! $een

	"
	exit 127
fi
