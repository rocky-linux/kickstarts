text
lang en_US.UTF-8
keyboard us
timezone UTC --utc
# Disk
bootloader --append="rootdelay=300 console=ttyS0 earlyprintk=ttyS0  no_timer_check crashkernel=auto net.ifnames=0" --location=mbr --timeout=1
auth --enableshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=ssh
firstboot --disable
# Network information
network  --bootproto=dhcp --device=link --activate --onboot=on
# Root password
services --disabled="kdump" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd,waagent"
rootpw --iscrypted thereisnopasswordanditslocked

# Partition Stuff
zerombr
clearpart --all --initlabel 
part /boot --fstype xfs --size 1024 --asprimary --ondisk vda
part /boot/efi --fstype vfat --size 512 --asprimary --ondisk vda
reqpart
part pv.01     --size=1    --ondisk=vda      --asprimary --grow
volgroup rocky pv.01
logvol / --vgname=rocky --size=8000 --name=root --grow --mkfsoptions "-m bigtime=0,inobtcount=0"
shutdown

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

# some stuff that's missing from core or explicitly setting
tar
rsync
dhcp-client
NetworkManager
rng-tools
dnf-utils
chrony
WALinuxAgent
hyperv-daemons

-biosdevname
-plymouth
-iprutils
-langpacks-*
-langpacks-en
-qemu-guest-agent
%end

%post --erroronfail
passwd -d root
passwd -l root

# Common Cloud Tweaks
# setup systemd to boot to the right runlevel
rm -f /etc/systemd/system/default.target
ln -s /lib/systemd/system/multi-user.target /etc/systemd/system/default.target
echo .

# remove linux-firmware as we're virt and it's half a gig
dnf -C -y remove linux-firmware

# Remove firewalld; it is required to be present for install/image building.
# but we dont ship it in cloud
dnf -C -y remove firewalld --setopt="clean_requirements_on_remove=1"
dnf -C -y remove avahi\* 
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

echo "virtual-guest" > /etc/tuned/active_profile

cat << EOF | tee -a /etc/NetworkManager/conf.d/dhcp-timeout.conf
# Configure dhcp timeout to 300s by default
[connection]
ipv4.dhcp-timeout=300
EOF

cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# Remove build-time resolvers to fix #16948
truncate -s 0 /etc/resolv.conf

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

# azure settings
# Configure waagent for cloud-init
sed -i 's/Provisioning.UseCloudInit=n/Provisioning.UseCloudInit=y/g' /etc/waagent.conf
sed -i 's/Provisioning.Enabled=y/Provisioning.Enabled=n/g' /etc/waagent.conf

# Azure: handle sr-iov and networkmanaeger
cat << EOF | tee -a /etc/udev/rules.d/68-azure-sriov-nm-unmanaged.rules
# Accelerated Networking on Azure exposes a new SRIOV interface to the VM.
# This interface is transparently bonded to the synthetic interface,
# so NetworkManager should just ignore any SRIOV interfaces.
SUBSYSTEM=="net", DRIVERS=="hv_pci", ACTION=="add", ENV{NM_UNMANAGED}="1"
EOF

# Azure: Time sync for linux
## Setup udev rule for ptp_hyperv
cat << EOF | tee -a /etc/udev/rules.d/98-hyperv-ptp.rules
## See: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/time-sync#check-for-ptp-clock-source
SUBSYSTEM=="ptp", ATTR{clock_name}=="hyperv", SYMLINK += "ptp_hyperv"
EOF

# Configure chrony to use ptp_hyperv
cat << EOF | tee -a /etc/chrony.conf
# Setup hyperv PTP device as refclock
refclock PHC /dev/ptp_hyperv poll 3 dpoll -2 offset 0 stratum 2
EOF

# Azure: Blacklist modules
cat << EOF | tee -a /etc/modprobe.d/azure-blacklist.conf
blacklist amdgpu
blacklist nouveau
blacklist radeon
EOF

# Azure: cloud-init customizations for Hyperv
cat << EOF | tee /etc/cloud/cloud.cfg.d/10-azure-kvp.cfg
# Enable logging to the Hyper-V kvp in Azure
reporting:
  logging:
    type: log
  telemetry:
    type: hyperv
EOF

# Kernel and Drivers
# Add drivers when building in VMWare, Vbox, or KVM (KVM)
cat << EOF | tee -a /etc/dracut.conf.d/80-azure.conf
add_drivers+=" hv_vmbus hv_netvsc hv_storvsc "
EOF

dracut -f -v

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

# rocky cloud user
sed -i 's/name: cloud-user/name: rocky/g' /etc/cloud/cloud.cfg
echo -e 'rocky\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers

# this shouldn't be the case, but we'll do it anyway
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/product-id.conf
sed -i 's|^enabled=1|enabled=0|' /etc/yum/pluginconf.d/subscription-manager.conf

dnf clean all
truncate -c -s 0 /var/log/dnf.log

# XXX instance type markers - MUST match Rocky Infra expectation
echo 'azure' > /etc/yum/vars/infra

# Azure Cleanup
sudo rm -f /var/log/waagent.log
sudo cloud-init clean
waagent -force -deprovision+user

# Common cleanup
rm -f ~/.bash_history
export HISTSIZE=0

rm -f /var/lib/systemd/random-seed
rm -rf /root/anaconda-ks.cfg
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf "/var/lib/yum/*"
rm -rf "/var/log/anaconda*"
rm -rf /var/log/yum.log

# Wipe machineid
cat /dev/null > /etc/machine-id

# Fix selinux
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

true

%end


