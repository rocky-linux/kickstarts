# Kickstart to build Rocky 8 image for Raspberry Pi 4 hardware (aarch64)
#

# Disk setup
clearpart --initlabel --all
part /boot --asprimary --fstype=vfat --size=300 --label=boot
part swap --asprimary --fstype=swap --size=512 --label=swap
part / --asprimary --fstype=ext4 --size=2800 --label=RPIROOT

# Repos setup:
url --url http://download.rockylinux.org/stg/rocky/9/BaseOS/aarch64/os/
repo --name="BaseOS"     --baseurl=http://download.rockylinux.org/stg/rocky/9/BaseOS/aarch64/os/ --cost=100
repo --name="AppStream"  --baseurl=http://download.rockylinux.org/stg/rocky/9/AppStream/aarch64/os/ --cost=200 --install
repo --name="CRB" --baseurl=http://download.rockylinux.org/stg/rocky/9/CRB/aarch64/os/ --cost=300 --install
# Rocky Rpi kernel repo, we need a more permanent place for this:
repo --name="rockyrpi" --baseurl=https://download.rockylinux.org/stg/sig/9/altarch/aarch64/altarch-rockyrpi/ --cost=20
repo --name="rockyextras" --baseurl=https://download.rockylinux.org/stg/rocky/9/extras/aarch64/os/  --cost=20

# Install process:
#text
keyboard us --xlayouts=us --vckeymap=us
rootpw --lock
# FIXME user creation here does not work ?
# user --name="rocky" --password="rockylinux" --plaintext --gecos="Rocky default user" --groups=wheel --uid=1000
timezone --isUtc --nontp UTC
selinux --enforcing
firewall --enabled --port=22:tcp
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=sshd,NetworkManager,chronyd,cpupower
shutdown
bootloader --location=none
lang en_US.UTF-8
skipx

# Package selection:
%packages
@core
#-grub2-tools-minimal
#-grub2-tools
#-grubby
#-grub2-common
chrony
cloud-utils-growpart
net-tools
NetworkManager-wifi
vim
bash-completion
nano
kernel-tools

# Need these for setting default locale of en-US:
langpacks-en
glibc-all-langpacks

# will enable rocky-release-rpi after full 9 release (and we have it in the -extras repo)
rocky-release-rpi
raspberrypi2-firmware
raspberrypi2-kernel4

%end

# Post install scripts:
%post

# Write initial boot line to cmdline.txt (we will update the root partuuid further down)
cat > /boot/cmdline.txt << EOF
console=ttyAMA0,115200 console=tty1 root= rootfstype=ext4 elevator=deadline rootwait
EOF

# Apparently kickstart user was not working, attempt to do it here?
/sbin/useradd -c "Rocky Linux default user" -G wheel -m -U rocky
echo "rockylinux" | passwd --stdin  rocky

# Need to write several files to help with various things here.
# First, the all-important README :

cat >/home/rocky/README << EOF
== Rocky 9 Raspberry Pi Image ==

This is a Rocky 9 install intended for Raspberry Pi 3b and 4 devices (architecture is aarch64).

This image WILL NOT WORK on a Raspberry Pi 1 or 2 (1.1 or earlier), we are 64-bit only, and have no support for 32-bit ARM processors.  Sorry :-/.

The newer Pi Zero devices should be supported, as well as the Raspberry Pi 2 version 1.2 boards, which are 64-bit


IMAGE NOTES / DIFFERENCES FROM STOCK ROCKY 8:
  
  - Based on Rocky Linux 9, points to production Rocky 9 aarch64 repositories
  - Includes script that fixes the wifi.  Simple edit of a txt firmware settings file.  Will need to be run whenever linux-firmware gets upgraded
  - Includes @minimal-install , plus a few quality of life packages like vim, bash-completion, etc.
  - Initial User "rocky" (default password: "rockylinux").  Root password disabled, rocky user is a sudoer
  - Partitions are 300 MB /boot , 512 MB swap, 2800 MB rootfs.  Requires a 4 GB or larger storage device to serve as your disk

GROW YOUR PARTITION: 

If you want to automatically resize your root (/ ) partition, just type the following (as root user):
sudo rootfs-expand

It should fill your main rootfs partition to the end of the disk.

Thanks for your interest on Rocky-on-Rpi, feel free to share your experience or contribute in our chat channel at:  https://chat.rockylinux.org/rocky-linux/channels/altarch  !

-The Rocky Linux Team

EOF

# Run the fix-wifi script (extracts the .xz firmware) - should be installed via the rocky-release-rpi package
# (shouldn't be needed anymore - fixed in newer rpi kernel builds)
#fix-wifi-rpi.sh

# Cleanup before shipping an image

# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Ensure no ssh keys are present
rm -f "/etc/ssh/*_key*"

# Clean yum cache
yum clean all

# Fix weird sssd bug, where it gets its folder owned by the unbound user:
chown -R sssd:sssd /var/lib/sss/{db,pipes,mc,pubconf,gpo_cache}

# Setting tuned profile to powersave by default -> sets the CPU governor to "ondemand".  This prevents overheating issues
cat > /etc/sysconfig/cpupower << EOF
# See 'cpupower help' and cpupower(1) for more info
CPUPOWER_START_OPTS="frequency-set -g ondemand"
CPUPOWER_STOP_OPTS="frequency-set -g ondemand"
EOF

%end

# Add the PARTUUID of the rootfs partition to the kernel command line
# We must do this *outside* of the chroot, by grabbing the UUID of the loopmounted rootfs
%post --nochroot

# Extract the UUID of the rootfs partition from /etc/fstab
UUID_ROOTFS="$(/bin/cat $INSTALL_ROOT/etc/fstab | \
/bin/awk -F'[ =]' '/\/ / {print $2}')"

# Get the PARTUUID of the rootfs partition
PART_UUID_ROOTFS="$(/sbin/blkid  "$(/sbin/blkid --uuid $UUID_ROOTFS)" | \
/bin/awk '{print $NF}' | /bin/tr -d '"' )"

# Configure the kernel commandline
/bin/sed -i "s/root= /root=${PART_UUID_ROOTFS} /" $INSTALL_ROOT/boot/cmdline.txt
echo "cmdline.txt looks like this, please review:"
/bin/cat $INSTALL_ROOT/boot/cmdline.txt

# Extract UUID of swap partition:
UUID_SWAP=$(/bin/grep 'swap'  $INSTALL_ROOT/etc/fstab  | awk '{print $1}' | awk -F '=' '{print $2}')

# Fix swap partition: ensure page size is 4096 (differs on the aarch64 AWS build host)
/usr/sbin/mkswap -L "_swap" -p 4096  -U "${UUID_SWAP}"  /dev/disk/by-uuid/${UUID_SWAP}

%end
%post
# WiFi fix on Pi 3 Model B(image wont boot on Pi 3B w/o this fix) 
cd /lib/firmware/brcm
xz -d -k brcmfmac43430-sdio.raspberrypi,3-model-b.txt.xz
%end

