text
lang en_US.UTF-8
keyboard us
timezone UTC --utc
# Disk
bootloader --append="console=ttyS0,115200n8 console=tty0 net.ifnames=0 rd.blacklist=nouveau nvme_core.io_timeout=4294967295" --location=mbr --timeout=1
auth --enableshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=ssh
firstboot --disable
# Network information
network  --bootproto=dhcp --device=link --activate --onboot=on
# Root password
services --disabled="kdump,rhsmcertd" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd"
rootpw --iscrypted thereisnopasswordanditslocked

# Partition stuff - Should work for x86 and aarch64
zerombr
clearpart --all --initlabel 
part /boot --fstype xfs --size 1024 --asprimary --ondisk vda
part /boot/efi --fstype vfat --size 512 --asprimary --ondisk vda
reqpart
part pv.01     --size=1    --ondisk=vda      --asprimary --grow
volgroup rocky pv.01
logvol / --vgname=rocky --size=8000 --name=root --grow --mkfsoptions "-m bigtime=0,inobtcount=0"
shutdown

%pre --erroronfail
/usr/sbin/parted -s /dev/vda mklabel gpt
%end

%packages
@core
rocky-release
kernel
yum-utils
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
gdisk
dracut-config-generic
grub2
firewalld

# some stuff that's missing from core or things we want
tar
rsync
dhcp-client
NetworkManager
rng-tools

-biosdevname
-plymouth
-iprutils
-langpacks-*
-langpacks-en
%end

%post --erroronfail
passwd -d root
passwd -l root

# setup systemd to boot to the right runlevel
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

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

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

if ! grep -q growpart /etc/cloud/cloud.cfg; then
  sed -i 's/ - resizefs/ - growpart\n - resizefs/' /etc/cloud/cloud.cfg
fi

# rocky cloud user
sed -i 's/name: cloud-user/name: rocky/g' /etc/cloud/cloud.cfg
echo -e 'rocky\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

# this shouldn't be the case, but we'll do it anyway
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/product-id.conf
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

dnf clean all
truncate -c -s 0 /var/log/dnf.log

# XXX instance type markers - MUST match Rocky Infra expectation
echo 'ec2' > /etc/yum/vars/infra

rm -rf /var/log/yum.log
rm -rf /var/lib/yum/*
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf /root/anaconda-ks.cfg
rm -rf /var/log/anaconda*

touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

# remove these for ec2 debugging
sed -i -e 's/ rhgb quiet//' /boot/grub/grub.conf

cat > /etc/modprobe.d/blacklist-nouveau.conf << EOL
blacklist nouveau
EOL

# enable resizing on copied AMIs
echo 'install_items+=" sgdisk "' > /etc/dracut.conf.d/sgdisk.conf

echo 'add_drivers+=" xen-netfront xen-blkfront "' > /etc/dracut.conf.d/xen.conf
# Rerun dracut for the installed kernel (not the running kernel):
KERNEL_VERSION=$(rpm -q kernel --qf '%{V}-%{R}.%{arch}\n')
dracut -f /boot/initramfs-$KERNEL_VERSION.img $KERNEL_VERSION

cat /dev/null > /etc/machine-id

cat >> /etc/chrony.conf << EOF

# Amazon Time Sync Service
server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4
EOF

%end

