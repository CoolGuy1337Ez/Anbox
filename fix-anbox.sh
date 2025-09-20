#!/bin/bash
set -e

# Helpers
die() { echo "ERROR: $1"; exit 1; }

echo "[0/6] Cloning CoolGuy1337Ez/Anbox repo..."
if [ ! -d ~/Anbox ]; then
    git clone https://github.com/CoolGuy1337Ez/Anbox.git ~/Anbox
else
    echo "→ Repo already exists, updating..."
    cd ~/Anbox && git pull
    cd -
fi

echo "[1/6] Checking kernel modules repo..."
# Clone if not present
if [ ! -d ~/anbox-modules ]; then
    echo "→ Cloning anbox kernel modules from GitHub..."
    git clone https://github.com/anbox/anbox-modules.git ~/anbox-modules
else
    echo "→ Module source already cloned; updating..."
    cd ~/anbox-modules && git pull
    cd -
fi

echo "[2/6] Build & install ashmem + binder via DKMS..."
cd ~/anbox-modules
if [ -f INSTALL.sh ]; then
    chmod +x INSTALL.sh
    sudo ./INSTALL.sh
else
    echo "No INSTALL.sh found; try manual DKMS install"
    sudo apt update
    sudo apt install -y dkms linux-headers-$(uname -r)
    sudo cp -r ashmem /usr/src/anbox-ashmem-1
    sudo cp -r binder /usr/src/anbox-binder-1
    sudo dkms install anbox-ashmem/1
    sudo dkms install anbox-binder/1
fi
cd -

echo "[3/6] Loading kernel modules..."
sudo modprobe ashmem_linux || die "Failed to load ashmem_linux"
sudo modprobe binder_linux || die "Failed to load binder_linux"

echo "[4/6] Checking Android image via mirror..."
IMG_PATH="/var/lib/anbox/android.img"
if [ ! -f "${IMG_PATH}" ]; then
    echo "→ Downloading image from GitHub mirror..."
    sudo mkdir -p /var/lib/anbox
    sudo wget https://github.com/AkihiroSuda/anbox-android-images-mirror/releases/download/snapshot-20180719/android_amd64.img \
         -O "${IMG_PATH}"
else
    echo "→ Image exists; you may want to verify its SHA256 if required."
fi

echo "[5/6] Moving into Anbox/main directory..."
cd ~/Anbox/main
echo "→ Now inside $(pwd)"

echo "[6/6] Starting Anbox session manager..."
anbox session-manager
