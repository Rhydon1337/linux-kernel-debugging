# Linux Kernel Debugging
How to create a setup for linux kernel debugging using buildroot, qemu and gdb.

# Part 1: Compile linux kernel and rootfs
We are going to compile linux kernel and rootfs using buildroot.
Buildroot supplies all the toolchain which needed for automate the process of compiling linux kernel, rootfs and bootloader.
Buildroot was created for creating linux embedded/minimal systmes.
However, if your purpose is developing or debugging linux kernel its really good solution.

First, Clone buildroot repository (latest version):

1. cd ~/workspace
2. git clone https://github.com/buildroot/buildroot.git
3. cd buildroot

## Config buildroot
Now we need to configure buildroot in order to build every packages with debug symbols.
We also will need to ssh to the vm, then we will include in our rootfs openssh.

4. make qemu_x86_64_defconfig // Generate buildroot default config
5. make menuconfig

* In Build options, toggle “build packages with debugging symbols”
* In System configuration, untoggle "Run a getty (login prompt) after boot"
* In System configuration, enter root password
* In Target packages, Networking applications, toggle "openssh"
* In Filesystem images, change to ext4 root filesystem

#### Notes: 
If you want to tell buildroot to download and compile antoher version of linux kernel:
* In Toolchain, change “linux version” to <version_you_want>
* In Toolchain, change “Custom kernel version headers series” to <version_you_want>
* In Kernel, change “Kernel version" to <version_you_want>

## Config linux kernel
Now we are going to configure linux kernel in order to compile it with debug symbols.
Before opening the menuconfig it will trigger buildroot to download linux kernel source code.

6. make linux-menuconfig

* In “Kernel hacking”, toggle “Kernel debugging”
* In “Kernel hacking”, toggle “Compile the kernel with debug info”
* In “Kernel hacking”, toggle “Compile the kernel with frame pointers”

## Compile linux kernel and rootfs
Now lets compile everything:

7. make -j8

Improtant files:

* output/build/linux-<version> contains the downloaded kernel source code
* output/images/bzImage is the compressed kernel image
* output/images/rootfs.ext4 is the rootfs
* output/build/linux-<version>/vmlinux is the raw kernel image

# Part 2: Debugging linux kernel using qemu and gdb

After we compiled linux kernel and rootfs we can debug it.
Our emulator will be qemu because qemu is really lightweight emulator that can be easily conigured to run almost anything and qemu works fine with kvm which improves the performence.

First, we need to convert our raw rootfs to qemu format which will be later used for creating snapshot.

Note: rootfs.ext4 is just a symlink to rootfs.ext2

8. qemu-img convert -f raw -O qcow2 rootfs.ext2 rootfs.qcow2

## Launch the vm
9. sudo qemu-system-x86_64 -enable-kvm -cpu host -s -kernel bzImage  -m 2048 -hda rootfs.qcow2 -append "root=/dev/sda rw nokaslr" -net nic,model=virtio -net user,hostfwd=tcp::5555-:22

Lets explain our command:
* -enable-kvm -> kvm is a virtualization solution for linux which use hardware virtualization extensions, we will use it in order to improve the vm performence
* -cpu host -> use host cpu, we will use it in order to improve the vm performence
* -s -> qemu will open a gdbserver on TCP port 1234
* -kernel -> path to the compiled kernel image
* -m -> amount of memory of the vm
* -hda -> path to disk image in our case the rootfs (and bootloader) 
* -append -> send command line arguments to the linux kernel
* -net nic,model=virtio -> connect a network interface
* -net user,hostfwd=tcp::5555-:22 -> in order to use ssh we will forward tcp traffic from host port 5555 to guest port 22

## Setup ssh (nice to have)
After launcing the vm you should see buildroot login the username is root and use the password which we configured earlier.
**Add "PermitRootLogin yes" to /etc/ssh/sshd_config in order to enable root login using ssh.**
Now you can open the terminal on the host and execute:
ssh -p 5555 root@localhost

## Take a snapshot
We will switch to qemu console in order to take the snapshot. 

10. press Ctrl+Alt+2
11. savevm <snapshot_name>

If you want to launch the vm from a snapshot:

12. sudo qemu-system-x86_64 -enable-kvm -cpu host -s -kernel bzImage  -m 2048 -hda rootfs.qcow2 -append "root=/dev/sda rw nokaslr" -net nic,model=virtio -net user,hostfwd=tcp::5555-:22 -loadvm <snapshot_name>

## Start the debugging session
Now we are going to attach to our vm and the debug the kernel, we will also use our symbols to the kernel. 

13. cd output/build/linux-{version}
14. gdb ./vmlinux
15. target remote :1234

And now you got a kernel debugging session. 

**DONE!!!**
