#!/bin/sh
(
BINARIES_DIR="${0%/*}/"
cd ${BINARIES_DIR}

if [ "${1}" = "serial-only" ]; then
    EXTRA_ARGS='-nographic'
else
    EXTRA_ARGS='-serial stdio'
fi

export PATH="../host/bin:${PATH}"
exec qemu-system-x86_64 -s -monitor unix:qemu-monitor-socket,server,nowait -enable-kvm -cpu host -m 2048 -M pc -kernel bzImage -hda rootfs.qcow2 -append "rootwait root=/dev/sda console=tty1 console=ttyS0rw nokaslr"  -net nic,model=virtio -net user,hostfwd=tcp::5555-:22  ${EXTRA_ARGS}
)
