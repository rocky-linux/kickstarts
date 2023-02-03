%include rocky-cloud-base.ks
%include rocky-cloud-parts-base.ks
%include rocky-cloud-base-packages.ks

bootloader --append="console=ttyS0,115200n8 no_timer_check crashkernel=auto net.ifnames=0" --location=mbr --timeout=1

%post --erroronfail
passwd -d root
passwd -l root

# Attempting to force legacy BIOS boot if we boot from UEFI
if [ "$(arch)" = "x86_64"  ]; then
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
