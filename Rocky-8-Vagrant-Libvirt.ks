#version=DEVEL
# Keyboard layouts
keyboard --vckeymap=us
# Root password
rootpw --plaintext vagrant
# System language
lang en_US
# Shutdown after installation
shutdown
user --name=vagrant --password=vagrant
# System timezone
timezone UTC --isUtc
# Use text mode install
text
# Network information
network  --bootproto=dhcp --device=link --activate
repo --name="plus" --baseurl=http://dl.rockylinux.org/pub/rocky/8/plus/$basearch/os
# Use network installation
url --url="https://download.rockylinux.org/stg/rocky/8/BaseOS/$basearch/os/"
# Firewall configuration
firewall --disabled
# Do not configure the X Window System
skipx

# System services
services --enabled="vmtoolsd"
# System bootloader configuration
bootloader --append="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop rd.lvm.vg=rocky rd.lvm.lv=rocky/root" --location=mbr --timeout=1

# Disk partitioning information
part /boot/efi --fstype="efi" --onpart=vda1
part /boot --fstype="xfs" --label=boot --onpart=vda2
part prepboot --fstype="prepboot" --onpart=vda3
part biosboot --fstype="biosboot" --onpart=vda4
part pv.01 --grow --size=1 --onpart=vda5
volgroup rocky pv.01
logvol / --grow --size=8000 --mkfsoptions="-m bigtime=0,inobtcount=0" --name=root --vgname=rocky

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
parted /dev/vda mkpart primary ext2 1106MiB 10.7GB
parted /dev/vda set 5 lvm on
%end

%post
# Attempting to force legacy BIOS boot if we boot from UEFI
if [ "$(arch)" = "x86_64"  ]; then
  dnf install grub2-pc-modules grub2-pc -y
  grub2-install --target=i386-pc /dev/vda
fi

# Ensure that the pmbr_boot flag is off
parted /dev/vda disk_set pmbr_boot off

# configure swap to a file
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

# sudo
echo "%vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

# Fix for https://github.com/CentOS/sig-cloud-instance-build/issues/38
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF

# sshd: disable password authentication and DNS checks
ex -s /etc/ssh/sshd_config <<EOF
:%substitute/^\(PasswordAuthentication\) yes$/\1 no/
:%substitute/^#\(UseDNS\) yes$/&\r\1 no/
:update
:quit
EOF
cat >>/etc/sysconfig/sshd <<EOF

# Decrease connection time by preventing reverse DNS lookups
# (see https://lists.centos.org/pipermail/centos-devel/2016-July/014981.html
#  and man sshd for more information)
OPTIONS="-u0"
EOF

# Default insecure vagrant key
mkdir -m 0700 -p /home/vagrant/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" >> /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Fix for issue #76, regular users can gain admin privileges via su
ex -s /etc/pam.d/su <<'EOF'
# allow vagrant to use su, but prevent others from becoming root or vagrant
/^account\s\+sufficient\s\+pam_succeed_if.so uid = 0 use_uid quiet$/
:append
account   [success=1 default=ignore] \\
        pam_succeed_if.so user = vagrant use_uid quiet
account   required  pam_succeed_if.so user notin root:vagrant
.
:update
:quit
EOF

# systemd should generate a new machine id during the first boot, to
# avoid having multiple Vagrant instances with the same id in the local
# network. /etc/machine-id should be empty, but it must exist to prevent
# boot errors (e.g.  systemd-journald failing to start).
:>/etc/machine-id

echo 'vag' > /etc/yum/vars/infra

# Blacklist the floppy module to avoid probing timeouts
echo blacklist floppy > /etc/modprobe.d/nofloppy.conf
chcon -u system_u -r object_r -t modules_conf_t /etc/modprobe.d/nofloppy.conf

# Customize the initramfs
pushd /etc/dracut.conf.d
# Enable VMware PVSCSI support for VMware Fusion guests.
echo 'add_drivers+=" vmw_pvscsi "' > vmware-fusion-drivers.conf
echo 'add_drivers+=" hv_netvsc hv_storvsc hv_utils hv_vmbus hid-hyperv "' > hyperv-drivers.conf
# There's no floppy controller, but probing for it generates timeouts
echo 'omit_drivers+=" floppy "' > nofloppy.conf
popd
# Fix the SELinux context of the new files
restorecon -f - <<EOF
/etc/sudoers.d/vagrant
/etc/dracut.conf.d/vmware-fusion-drivers.conf
/etc/dracut.conf.d/hyperv-drivers.conf
/etc/dracut.conf.d/nofloppy.conf
EOF

# Rerun dracut for the installed kernel (not the running kernel):
KERNEL_VERSION=$(rpm -q kernel --qf '%{version}-%{release}.%{arch}\n')
dracut -f /boot/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}

# Seal for deployment
rm -rf /etc/ssh/ssh_host_*
hostnamectl set-hostname localhost.localdomain
rm -rf /etc/udev/rules.d/70-*
%end

%addon com_redhat_kdump --disable
%end
%packages --instLangs=en
bash-completion
bzip2
chrony
cifs-utils
hyperv-daemons
man-pages
nfs-utils
open-vm-tools
rsync
yum-utils
-dracut-config-rescue
-iwl100-firmware
-iwl1000-firmware
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
-iwl6050-firmware
-iwl7260-firmware
-microcode_ctl
-plymouth

%end