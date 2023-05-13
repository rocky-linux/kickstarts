text
lang en_US.UTF-8
keyboard us
timezone --utc UTC
# Disk
bootloader --append="console=ttyS0,115200n8 no_timer_check crashkernel=auto net.ifnames=0" --location=mbr --timeout=1
auth --enableshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=ssh
firstboot --disable
# Network information
network  --bootproto=dhcp --device=link --activate --onboot=on
# Root password
services --disabled="kdump,rhsmcertd" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd"
rootpw --iscrypted thereisnopasswordanditslocked

# Disk partitioning information
# NOTE(neil): 2023-05-12 NONE of reqpart, clearpart, zerombr can be used. We
# are creating partitions manually in %pre to ensure proper ordering as
# Anaconda does NOT ensure the ordering `part` commands.
part /boot/efi --fstype="efi" --onpart=vda1
part /boot --fstype="xfs" --label=boot --onpart=vda2
part prepboot --fstype="prepboot" --onpart=vda3
part biosboot --fstype="biosboot" --onpart=vda4
part /         --size=8000 --fstype="xfs"    --mkfsoptions "-m bigtime=0,inobtcount=0" --grow --onpart=vda5
shutdown

%pre
# Clear the Master Boot Record
dd if=/dev/zero of=/dev/vda bs=512 count=1
# Create a new GPT partition table
parted /dev/vda mklabel gpt
# Create a partition for /boot/efi
parted /dev/vda mkpart primary fat32 1MiB 100MiB
parted /dev/vda set 1 boot on
# Create a partition for /boot
parted /dev/vda mkpart primary xfs 100MiB 1100MiB
# Create a partition for prep
parted /dev/vda mkpart primary 1100MiB 1104MiB
# Create a partition for bios_grub
parted /dev/vda mkpart primary 1104MiB 1105MiB
# Create a partition for LVM
parted /dev/vda mkpart primary xfs 1106MiB 10.7GB

%end

%packages
@core
rocky-release
dnf
kernel
yum
nfs-utils
dnf-utils
hostname
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-ivtv-firmware
-iwl1000-firmware
-iwl100-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware

cloud-init
cloud-utils-growpart
python3-jsonschema
dracut-config-generic
-dracut-config-rescue
firewalld

# some stuff that's missing from core or things we want
tar
tcpdump
rsync
rng-tools
cockpit-ws
cockpit-system
qemu-guest-agent
virt-what

-biosdevname
-plymouth
-iprutils
# Fixes an s390x issue
#-langpacks-*
-langpacks-en
%end

%post --erroronfail
passwd -d root
passwd -l root

# Attempting to force legacy BIOS boot if we boot from UEFI
if [ "$(arch)" = "x86_64" ]; then
  dnf install grub2-pc-modules grub2-pc -y
  grub2-install --target=i386-pc /dev/vda
fi

# Ensure that the pmbr_boot flag is off
parted /dev/vda disk_set pmbr_boot off

# setup systemd to boot to the right runlevel
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

# we don't need this in virt
dnf -C -y remove linux-firmware

# Remove firewalld; it is required to be present for install/image building.
# but we dont ship it in cloud
dnf -C -y remove firewalld --setopt="clean_requirements_on_remove=1"
dnf -C -y remove avahi\* 
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# this should *really* be an empty file - gotta make anaconda happy
truncate -s 0 /etc/resolv.conf

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
rm -f /etc/sysconfig/network-scripts/ifcfg-*

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
BOOTPROTOv6="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="yes"
PERSISTENT_DHCLIENT="1"
EOF

echo "virtual-guest" > /etc/tuned/active_profile

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

#systemctl mask tmp.mount

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# just in case
if ! grep -q growpart /etc/cloud/cloud.cfg; then
  sed -i 's/ - resizefs/ - growpart\n - resizefs/' /etc/cloud/cloud.cfg
fi
# temporary until 22.2
sed -i 's/^system_info:/locale: C.UTF-8\nsystem_info:/' /etc/cloud/cloud.cfg

# rocky cloud user
sed -i '1i # Modified for cloud image' /etc/cloud/cloud.cfg
echo -e 'rocky\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers
sed -i 's/name: cloud-user/name: rocky/g' /etc/cloud/cloud.cfg

# these shouldn't be enabled, but just in case
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/product-id.conf
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

dnf clean all

# XXX instance type markers - MUST match Rocky Infra expectation
echo 'genclo' > /etc/yum/vars/infra

rm -rf /var/log/yum.log
rm -rf /var/lib/yum/*
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf /root/anaconda-ks.cfg
rm -rf /var/log/anaconda*

echo "Fixing SELinux contexts."
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

rm -f /var/lib/systemd/random-seed
cat /dev/null > /etc/machine-id

# reorder console entries
#sed -i 's/console=tty0/console=tty0 console=ttyS0,115200n8/' /boot/grub2/grub.cfg

true

%end
