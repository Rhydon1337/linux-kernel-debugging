# Linux Kernel Debugging
How to create a setup for linux kernel debugging using buildroot, qemu and gdb.

# Part 1: Compile linux kernel and rootfs
We are going to compile linux kernel and rootfs using buildroot.
Buildroot supplies all the toolchain which needed for automate the process of compiling linux kernel and rootfs.
Buildroot was created for creating linux embedded/minimal systems.
However, if your purpose is developing or debugging the linux kernel its really good solution.

First, Clone buildroot repository (latest version):

1. cd ~/workspace
2. git clone https://github.com/buildroot/buildroot.git
3. cd buildroot

## Config buildroot
Now we need to configure buildroot in order to build every packages with debug symbols.
In order to be able to ssh to the vm we'll add the openssh package.

4. make qemu_x86_64_defconfig // Generate buildroot default config
5. make menuconfig


| Option | Corresponding config symbols                                                                                             |
| ------ | -------------------------------------------------------------------------------------------------------------------------|
| In Build options, toggle “build packages with debugging symbols”          | `BR2_ENABLE_DEBUG`                                    |
| In System configuration, untoggle "Run a getty (login prompt) after boot" | `BR2_TARGET_GENERIC_GETTY`                            |
| In System configuration, enter root password                              | `BR2_TARGET_GENERIC_ROOT_PASSWD`                      |
| In Target packages, Networking applications, toggle "openssh"             | `BR2_PACKAGE_OPENSSH`                                 |
| In Filesystem images, change to ext4 root filesystem                      | `BR2_TARGET_ROOTFS_EXT2` & `BR2_TARGET_ROOTFS_EXT2_4` |

> The path to the options may change between buildroot versions, if an option is missing validate the symbols
> are set appropriately using `cat .config | grep <symbol>` from buildroot's folder 

#### Notes: 
If you want to tell buildroot to download and compile antoher version of linux kernel:
* In Toolchain, change “linux version” to <version_you_want>
* In Toolchain, change “Custom kernel version headers series” to <version_you_want>
* In Kernel, change “Kernel version" to <version_you_want>

## Config linux kernel
Now we are going to configure linux kernel in order to compile it with debug symbols.
Before opening the menuconfig it will trigger buildroot to download linux kernel source code.

6. make linux-menuconfig

| Option | Corresponding config symbols                                                                                             |
| ------ | -------------------------------------------------------------------------------------------------------------------------|
| In “Kernel hacking”, toggle “Kernel debugging”                                                            | `CONFIG_DEBUG_KERNEL` |
| In “Kernel hacking/Compile-time checks and compiler options”, toggle “Compile the kernel with debug info” | `DEBUG_INFO`          |
| In “Kernel hacking”, toggle “Compile the kernel with frame pointers”                                      | `FRAME_POINTER`       |

## Compile linux kernel and rootfs
Now lets compile everything:

7. make -j8

Important files:

* output/build/linux-<version> contains the downloaded kernel source code
* output/images/bzImage is the compressed kernel image
* output/images/rootfs.ext4 is the rootfs
* output/build/linux-<version>/vmlinux is the raw kernel image

# Part 2: Debugging linux kernel using qemu and gdb

After we compiled the linux kernel and rootfs we can debug it.
Our emulator will be qemu because qemu is a really lightweight emulator that can be easily configured to run almost anything and qemu works fine with kvm which improves the performance.

8. First, we'll enable ssh connections by changing `sshd_config`
```
sudo -i
cd /path/to/buildroot/output/images
mkdir /mnt/dbg_kernel_fs
mount rootfs.ext2 /mnt/dbg_kernel_fs
echo "PermitRootLogin yes" >> /mnt/dbg_kernel_fs/etc/ssh/sshd_config
umount /mnt/dbg_kernel_fs
rmdir /mnt/dbg_kernel_fs
exit
```

Now we'll convert our raw rootfs to qemu format which will enable us to create snapshots later on.

9. 
```
cd ./output/images
qemu-img convert -f raw -O qcow2 rootfs.ext2 rootfs.qcow2
```

> Note: rootfs.ext4 is just a symlink to rootfs.ext2

## Launch the vm

Copy/Replace `start-qemu.sh` from this repo into buildroot/output/images.
This shell script runs qemu with customized flags explained below:

* -monitor unix:qemu-monitor-socket,server,nowait -> creates a socket file named `qemu-monitor-socket` to which we'll connect with socat for the qemu monitoring
* -enable-kvm -> kvm is a virtualization solution for linux which use hardware virtualization extensions, we will use it in order to improve the vm performance
* -cpu host -> use host cpu, we will use it in order to improve the vm performence
* -s -> qemu will open a gdbserver on TCP port 1234
* -m 2048 -> amount of memory of the vm (2mb in our example)
* -hda -> path to the root filesystem image in our case the rootfs 
* -append -> send command line arguments to the linux kernel
* -net nic,model=virtio -> connect a network interface
* -net user,hostfwd=tcp::5555-:22 -> forwards tcp traffic from host port 5555 to guest port 22
which allows us to use ssh.


Now we can launch our vm:

11. ./start-qemu.sh

#### SSH to guest
`ssh root@localhost -p 5555`


## Snapshots
In order to take snapshots we'll connect to the qemu monitor 
11. socat stdio,echo=0,icanon=0 unix-connect:qemu-monitor-socket

saving and loading snapshots can be done in the following manner respectively:

* savevm <snapshot_name>

* loadvm <snapshot_name>

## Start the debugging session
Now we are going to attach to our vm and the debug the kernel, we will also use our symbols to the kernel. 

12. cd output/build/linux-{version}
13. gdb ./vmlinux
14. target remote :1234

And now you got a kernel debugging session. 

**DONE!!!**
