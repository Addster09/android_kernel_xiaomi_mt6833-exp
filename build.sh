#!/bin/bash

# --- Configuration ---
# Generic MT6833 Defconfig
DEFCONFIG="k6833v1_64_k419_defconfig"

# Paths
TC_DIR="$HOME/toolchains/neutron-clang"
AK3_DIR="$HOME/AnyKernel3"
ZIPNAME="Alps-Base-MT6833.zip"

# Setup Environment
export PATH="$TC_DIR/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64

# Speed
export USE_CCACHE=1
export CCACHE_EXEC=$(which ccache)

# --- Build ---
mkdir -p out
if [ ! -f "out/.config" ]; then
    echo "Applying $DEFCONFIG..."
    make O=out "$DEFCONFIG"
fi

echo "Building..."
# KCFLAGS includes ALL compiler suppressions needed for the Oplus/MTK code
make -j$(nproc --all) O=out \
    CC="ccache clang" \
    LLVM=1 \
    LLVM_IAS=1 \
    KCFLAGS="-Wno-pointer-to-int-cast -Wno-void-pointer-to-int-cast -Wno-unused-but-set-variable -Wno-strict-prototypes -Wno-single-bit-bitfield-constant-conversion -Wno-enum-conversion -Wno-misleading-indentation" \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    Image.gz dtbs

# --- Check ---
if [ -f "out/arch/arm64/boot/Image.gz" ]; then
    echo "Build Success! Kernel and DTBs are ready."
    
    # NOTE: The combined Image.gz-dtb must be created manually after build.
    DTB_FILE="out/arch/arm64/boot/dts/mediatek/mt6833.dtb"
    FINAL_IMG="out/arch/arm64/boot/Image.gz-dtb"
    
    if [ -f "$DTB_FILE" ]; then
        # Create the final file for AnyKernel
        cat out/arch/arm64/boot/Image.gz "$DTB_FILE" > "$FINAL_IMG"
        
        # Copy to AnyKernel3 if available
        [ -d "$AK3_DIR" ] && cp "$FINAL_IMG" "$AK3_DIR/"
        echo "Final Image.gz-dtb created."
    fi

else
    echo "Build Failed."
fi
