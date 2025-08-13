#!/usr/bin/env bash

# Version of the driver we are downloading
MODULE_VERSION="9.016.00"
# Name of the device for which we are downloading the driver
MODULE_NAME="r8125"
# Name of the directory in the archive
DIRECTORY_NAME="$MODULE_NAME-$MODULE_VERSION"
# URL of the driver archive
DRIVER_DOWNLOAD_URL="https://rtitwww.realtek.com/rtdrivers/cn/nic1/$DIRECTORY_NAME.tar.bz2"
# Save to directory
SAVE_TO_DIRECTORY="/usr/src"

# Function to check and remove old version of the driver
remove_old_versions() {
    local old_versions
    old_versions=$(dkms status | grep "^$MODULE_NAME" | grep -v "$MODULE_VERSION" | awk '{print $2}' | tr -d ',')
    for ver in $old_versions; do
        echo "Removing old version: $ver"
        dkms remove -m $MODULE_NAME -v $ver --all
    done
}

# Root and environment checks
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or log in as root."
    exit 1
fi

if [ ! -f "/etc/pve/version" ]; then
    echo "This script is intended to be run on a Proxmox environment only."
    exit 1
fi

# Download and prepare the driver
wget -e "on-error=abort" -O "$SAVE_TO_DIRECTORY/$DIRECTORY_NAME.tar.bz2" "$DRIVER_DOWNLOAD_URL" || {
    echo "Failed to download the driver. Please check the URL or network connectivity."
    exit 1
}
# Extract the archive
tar -xvf "$SAVE_TO_DIRECTORY/$DIRECTORY_NAME.tar.bz2" -C "$SAVE_TO_DIRECTORY"
# Remove the archive
rm "$SAVE_TO_DIRECTORY/$DIRECTORY_NAME.tar.bz2"

# Ensure required packages are installed
apt install -y dkms build-essential pve-headers-$(uname -r)

# Create the DKMS configuration file
cat << EOF > "$SAVE_TO_DIRECTORY/$DIRECTORY_NAME/dkms.conf"
PACKAGE_NAME="$MODULE_NAME"
PACKAGE_VERSION="$MODULE_VERSION"
BUILT_MODULE_NAME[0]="$MODULE_NAME"
BUILT_MODULE_LOCATION[0]="src/"
DEST_MODULE_LOCATION[0]="/kernel/drivers/net/ethernet"
AUTOINSTALL="YES"
MAKE[0]="make -C \\\$kernel_source_dir M=\\\$dkms_tree/\\\$PACKAGE_NAME/\\\$PACKAGE_VERSION/build/src modules"
CLEAN="make -C \\\$kernel_source_dir M=\\\$dkms_tree/\\\$PACKAGE_NAME/\\\$PACKAGE_VERSION/build/src clean"
EOF

# Remove old versions of the driver
remove_old_versions

# Unload the module if it is currently loaded
if lsmod | grep -q "^$MODULE_NAME "; then
    echo "Unloading module $MODULE_NAME..."
    rmmod $MODULE_NAME
fi

# Add, build, and install the new module
dkms add -m $MODULE_NAME -v $MODULE_VERSION
dkms build -m $MODULE_NAME -v $MODULE_VERSION
dkms install -m $MODULE_NAME -v $MODULE_VERSION

# Check if the module is installed and loaded
if dkms status -m "$MODULE_NAME" -v "$MODULE_VERSION" | grep -q "installed"; then
    echo "Module $MODULE_NAME version $MODULE_VERSION is installed."
    if ! lsmod | grep -q "^$MODULE_NAME "; then
        modprobe $MODULE_NAME
        echo "Module $MODULE_NAME is now loaded."
    else
        echo "Module $MODULE_NAME is already loaded."
    fi
else
    echo "Failed to install module $MODULE_NAME version $MODULE_VERSION."
    exit 1
fi

# Ensure the module is added to /etc/modules for auto-loading
if ! grep -q "^$MODULE_NAME$" /etc/modules; then
    echo "$MODULE_NAME" >> /etc/modules
    echo "Module $MODULE_NAME added to /etc/modules for auto-loading."
else
    echo "Module $MODULE_NAME is already in /etc/modules for auto-loading."
fi
