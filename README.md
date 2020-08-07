# Linux-Kernel-Debugging
How to create a setup for linux kernel debugging using buildroot and qemu

We are going to compile linux kernel and rootfs using buildroot.
Buildroot supply all the toolchain which needed for automate the process of compiling linux kernel, rootfs and bootloader.
Buildroot was created for creating linux embedded/minimal systmes.
However, if your purpose is developing or debugging linux kernel its really good solution.


First, Clone buildroot repository (latest version):

1. cd ~/workspace
2. git clone (https://github.com/buildroot/buildroot.git)
3. cd buildroot

Now we need to configure buildroot in order to build every packages with debug symbols.
We also will need to ssh to the vm, then we will include in our rootfs openssh.

# Notes: 
If you want to tell buildroot to download and compile antoher version of linux kernel change:
* In Toolchain, change “linux version” to <version_you_want>
* In Toolchain, change “Custom kernel version headers series” to <version_you_want>
* In Kernel, change “Kernel version" to <version_you_want>

# Generate Buildroot default config
4. make qemu_x86_64_defconfig

# Config Buildroot
5. make menuconfig

* In Build options, toggle “build packages with debugging symbols”
* In System configuration, untoggle "Run a getty (login prompt) after boot"
* In System configuration, enter root password
* In Target packages, Networking applications, toggle "openssh"
* In Filesystem images, change to ext4 root filesystem

Now we are going to configure linux kernel in order to compile it with debug symbols.
Before opening the menuconfig it will trigger Buildroot linux kernel source code.

# Config linux kernel
6. make linux-menuconfig

* In “Kernel hacking”, toggle “Kernel debugging”
* In “Kernel hacking”, toggle “Compile the kernel with debug info”
* In “Kernel hacking”, toggle “Compile the kernel with frame pointers”

# Compile linux kernel and rootfs
Now lets compile everything:
7. make

