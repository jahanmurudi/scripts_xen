#!/bin/bash

#set -e  # Exit immediately if a command fails
#set -o pipefail  # Fail if any command in a pipeline fails

# Default SDK path
DEFAULT_SDK_PATH="/opt/poky/5.0/environment-setup-cortexa57-cortexa53-poky-linux"

# Read SDK path from command line or use default
SDK_PATH="${1:-$DEFAULT_SDK_PATH}"

# Set cross-compilation variables
export ARCH=aarch64
export CROSS_COMPILE=aarch64-linux-gnu-
#export SYSROOT=/usr/aarch64-linux-gnu

# Check if SDK path exists
if [ ! -f "$SDK_PATH" ]; then
    echo "Warning: SDK environment setup script not found at '$SDK_PATH'. Using default settings."
else
    echo "Sourcing SDK environment from: $SDK_PATH"
    source "$SDK_PATH"
fi

# Set additional build flags
export XEN_TARGET_ARCH=arm64
export LDFLAGS="-O1"
export CFLAGS="-O2 -pipe"

# Xen source directory (expects the user to have cloned it)
XEN_SRC_DIR="${XEN_SRC_DIR:-$PWD}"

# Verify Xen source directory
if [ ! -d "$XEN_SRC_DIR" ] || [ ! -f "$XEN_SRC_DIR/Makefile" ]; then
    echo "Error: Xen source directory '$XEN_SRC_DIR' is invalid!"
    exit 1
fi

cd "$XEN_SRC_DIR"

# Define output directory
BUILD_DIR="$HOME/xen-builds/rcar"
rm -rf $BUILD_DIR/*
mkdir -p "$BUILD_DIR"
LOG_FILE="$BUILD_DIR/build.log"

echo "Building Xen for R-Car..."
echo "Logs will be saved to $LOG_FILE"


# Clean previous builds
#echo "Cleaning previous builds..."
XEN_TARGET_ARCH=arm64 make distclean | tee "$LOG_FILE"


# Run configure script
echo "Running Xen configure script..."
XEN_TARGET_ARCH=arm64 ./configure --host=aarch64-linux-gnu --target=aarch64-linux-gnu   2>&1 | tee -a "$LOG_FILE" || exit 1

# Run menuconfig for manual configuration
echo "Running menuconfig for Xen..."
pushd xen
# make menuconfig
cd ..

# Build Xen hypervisor
echo "Building Xen hypervisor..."
make -j$(nproc) xen  | tee -a "$LOG_FILE"
#make -j$(nproc) tools | tee -a "$LOG_FILE"

# Copy Xen binary to output directory
XEN_BINARY_PATH="$XEN_SRC_DIR/dist/install/boot/xen"
if [ -f "$XEN_BINARY_PATH" ]; then
    echo "Copying Xen binary to build directory..."
    cp "$XEN_BINARY_PATH" "$BUILD_DIR/xen"
else
    echo "Error: Xen binary not found at expected path: $XEN_BINARY_PATH"
    exit 1
fi

# Create bootable image
echo "Creating bootable Xen image..."
mkimage -A arm64 -C none -T kernel -a 0x88080000 -e 0x88080000 -n "XEN" -d "$BUILD_DIR/xen" "$BUILD_DIR/xen-uImage"

if [ -f "$BUILD_DIR/xen-uImage" ]; then
    echo "Bootable Xen image created successfully at: $BUILD_DIR/xen-uImage"
else
    echo "Error: Failed to create Xen bootable image."
    exit 1
fi

# Build Xen FLASK policy
echo "Building Xen FLASK policy..."
make -C tools/flask/policy | tee -a "$LOG_FILE"

# Copy Xen FLASK policy files to output directory
echo "Copying Xen FLASK policy files to build directory..."
cp tools/flask/policy/xenpolicy* "$BUILD_DIR/"

# update your TFTP path
SRV_TFTP_PATH=/srv/tftp/jahan/xen_4_20/

# Copy images as well
echo "Copying images to output directory..."
sudo cp -r "$BUILD_DIR/xenpolic"* "$SRV_TFTP_PATH/xenpolicy"
sudo cp -r "$BUILD_DIR/xen-uImage"* "$SRV_TFTP_PATH/xen-uImage"

echo "Build complete!"
echo "Xen binary is available at: $BUILD_DIR/xen"
echo "Bootable Xen image is available at: $BUILD_DIR/xen-uImage"
echo "Xen FLASK policy files are available at: $BUILD_DIR/"
echo "Build log saved at: $LOG_FILE"
echo "Image copied at: $SRV_TFTP_PATH"

