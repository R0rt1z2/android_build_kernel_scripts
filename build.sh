#!/bin/bash

ARM_TOOLCHAIN="arm-linux-androideabi-4.9"
ARM64_TOOLCHAIN="aarch64-linux-android-4.9"
#NO_COMMIT_HISTORY="--depth=1"
GCC_RELEASE="oreo-release"
CLEAN=1
J_CORES="-j4"

if [ $# -eq 0 ]; then
	echo "[-] Usage: $0 kernel_folder (-d) (cores)"
	exit
fi

if [ -z $(which python) ]; then echo "[-] Python is missing!"; fi

if [ $# -gt 1 ]; then
	if [ $2 == "-d" ]; then
		echo "[?] Enabled dirty build..."
		CLEAN=0
	fi
fi

if [ $# -gt 2 ]; then
	echo "[?] Building with $3 cores..."
	J_CORES="-j$3"
fi

kernelfolder="$1"

if [ $CLEAN -eq 1 ]; then
	echo "[?] Cleaning out folder..."
	rm -rf OUT
	mkdir -p OUT
fi

export O=$PWD/OUT

if [ ! -d "$kernelfolder" ]; then
	echo "[-] Couldn't locate $kernelfolder!"
	exit
fi

read -p "[?] Enter the kernel ARCH (arm64/arm): "  kernelarch

if [[ ! $kernelarch =~ ^(arm64|arm)$ ]]; then
    echo "[-] Invalid arch!"
    exit
fi

read -p "[?] Enter the device codename for defconfig: "  device

defconfig="$device"_defconfig

read -p "[?] Enter the image name (Image.gz-dtb/zImage/zImage-dtb/Image): "  image

if [[ ! $image =~ ^(Image.gz-dtb|zImage|zImage-dtb|Image)$ ]]; then
    echo "[-] Invalid image!"
    exit
else
    echo "[?] Target image name: $image"
fi

if [ $kernelarch = "arm" ]; then
    export ARCH=arm
    export CROSS_COMPILE=$PWD/arm-linux-androideabi-4.9/bin/arm-eabi-
    if [ ! -d "$ARM_TOOLCHAIN" ]; then
		echo "[!] $ARM_TOOLCHAIN not found. Cloning it..."
		git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 $NO_COMMIT_HISTORY -b $GCC_RELEASE >&- 2>&-
    fi
elif [ $kernelarch = "arm64" ]; then
	export ARCH=arm64
	export CROSS_COMPILE=$PWD/aarch64-linux-android-4.9/bin/aarch64-linux-android-
	if [ ! -d "$ARM64_TOOLCHAIN" ]; then
		echo "[!] $ARM64_TOOLCHAIN not found. Cloning it..."
		git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 $NO_COMMIT_HISTORY -b $GCC_RELEASE >&- 2>&-
	fi
fi

echo "[?] Generating config"
make -C $kernelfolder $defconfig

echo "[?] Building for $defconfig"
make -C $kernelfolder $image $defconfig $J_CORES