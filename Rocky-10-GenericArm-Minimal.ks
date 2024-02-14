# Generated by pykickstart v3.41
#version=DEVEL
# Firewall configuration
firewall --enabled --port=22:tcp
# Keyboard layouts
# old format: keyboard us
# new format:
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
# Network information
network  --bootproto=dhcp --device=link --activate
# Shutdown after installation
shutdown
repo --name="rocky9-baseos" --baseurl=https://download.rockylinux.org/stg/rocky/10/BaseOS/aarch64/os/
repo --name="rocky9-appstream" --baseurl=https://download.rockylinux.org/stg/rocky/10/AppStream/aarch64/os/
repo --name="rocky9-powertools" --baseurl=https://download.rockylinux.org/stg/rocky/10/CRB/aarch64/os/
repo --name="instKern" --baseurl=https://rockyrepos.gnulab.org/gen_aarch64_el9/ --cost=100 --install
#Root password
rootpw --lock
# SELinux configuration
selinux --enforcing
# System services
services --enabled="sshd,NetworkManager,chronyd"
# System timezone
timezone UTC --utc --nontp
# Use network installation
url --url="https://download.rockylinux.org/stg/rocky/10/BaseOS/aarch64/os/"
# System bootloader configuration
bootloader --location=mbr --driveorder="sda"
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part /boot/efi --asprimary --fstype="efi" --size=512
part /boot --asprimary --fstype="ext4" --size=1024 --label=boot
part swap --asprimary --fstype="swap" --size=512 --label=swap
part / --asprimary --fstype="ext4" --size=3072 --label=rootfs

%pre

#End of Pre script for partitions
%end

%post
# Mandatory README file
cat >/root/README << EOF
== Rocky Linux 9 ==

If you want to automatically resize your / partition, just type the following (as root user):
rootfs-expand

EOF

%end

%post
# Setting correct yum variable to use raspberrypi kernel repo
#echo "generic" > /etc/dnf/vars/kvariant
#
# Creating rocky user and add to wheel group
/sbin/useradd -c "Rocky Linux default user" -G wheel -m -U rocky
echo "rockylinux" | passwd --stdin  rocky
# Generic efi filename for VMs
mkdir -p /boot/efi/EFI/BOOT
if [ -d /boot/efi/EFI/rocky/ ] && [ -f /boot/efi/EFI/rocky/grubaa64.efi ];then
    for j in grub.cfg grubenv;do
        mv -f /boot/grub2/${j} /boot/efi/EFI/rocky/
        ln -s ../efi/EFI/rocky/${j} /boot/grub2/${j}
    done
    cp -f /boot/efi/EFI/rocky/grubaa64.efi /boot/efi/EFI/BOOT/BOOTAA64.EFI
fi

cp -f /usr/share/uboot/rpi_3/u-boot.bin /boot/efi/rpi3-u-boot.bin
cp -f /usr/share/uboot/rpi_4/u-boot.bin /boot/efi/rpi4-u-boot.bin

rpm -e dracut-config-generic

#setup dtb link by running "creating 10-devicetree.install"
if [ -x /lib/kernel/install.d/10-devicetree.install ];then
    /lib/kernel/install.d/10-devicetree.install remove
fi

### Write /etc/sysconfig/kernel
cat << EOF > /etc/sysconfig/kernel
# Written by image installer
# UPDATEDEFAULT specifies if new-kernel-pkg should make new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel-core
EOF
chmod 644 /etc/sysconfig/kernel

### Write grub defaults, turn off OS probing as it is always wrong for image creation
cat << EOF > /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_RECOVERY="true"
GRUB_DISABLE_OS_PROBER="true"
GRUB_ENABLE_BLSCFG="false"
EOF
chmod 644 /etc/default/grub
# fixing the rpmdb
rpm --rebuilddb
# remove /boot/dtb for some rpi to boot
rm -f /boot/dtb
%end

%post
# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

%end

%post
cat >/usr/local/bin/rootfs-expand << EOF

#!/bin/bash
clear
part=\$(mount |grep '^/dev.* / ' |awk '{print \$1}')
if [ -z "\$part" ];then
    echo "Error detecting rootfs"
    exit -1
fi
dev=\$(echo \$part|sed 's/[0-9]*\$//g')
devlen=\${#dev}
num=\${part:\$devlen}
if [[ "\$dev" =~ ^/dev/mmcblk[0-9]*p\$ ]];then
    dev=\${dev:0:-1}
fi
if [ ! -x /usr/bin/growpart ];then
    echo "Please install cloud-utils-growpart (sudo yum install cloud-utils-growpart)"
    exit -2
fi
if [ ! -x /usr/sbin/resize2fs ];then
    echo "Please install e2fsprogs (sudo yum install e2fsprogs)"
    exit -3
fi
echo \$part \$dev \$num

echo "Extending partition \$num to max size ...."
growpart \$dev \$num
echo "Resizing ext4 filesystem ..."
resize2fs \$part
echo "Done."
df -h |grep \$part
EOF

chmod +x /usr/local/bin/rootfs-expand
%end

%packages
@core
NetworkManager-wifi
bash-completion
bcm2711-firmware
bcm2835-firmware
bcm283x-firmware
bcm283x-overlays
chrony
cloud-utils-growpart
dracut-config-generic
efibootmgr
glibc-langpack-en
grub2-common
grub2-efi-aa64
grub2-efi-aa64-modules
grubby
kernel
kernel-core
nano
net-tools
shim-aa64
systemd-udev
uboot-images-armv8
uboot-tools
-dracut-config-rescue
-java-11-*

%end
