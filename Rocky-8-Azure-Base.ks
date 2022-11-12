text
url --url https://dl.rockylinux.org/stg/rocky/8/BaseOS/$basearch/os/

auth --enableshadow --passalgo=sha512
shutdown
firewall --enabled --service=ssh
firstboot --disable
ignoredisk --only-use=vda
keyboard us
# System language
lang en_US.UTF-8
# Network information
network  --bootproto=dhcp --device=link --activate --onboot=on
network  --hostname=localhost.localdomain
# Root password
rootpw --iscrypted thereisnopasswordanditslocked
selinux --enforcing
services --disabled="kdump" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd"
timezone UTC --isUtc
# Disk
bootloader --append="rootdelay=300 console=ttyS0 earlyprintk=ttyS0  no_timer_check crashkernel=auto net.ifnames=0" --location=mbr --timeout=1 --boot-drive=vda
zerombr
clearpart --all --initlabel 
part /boot --fstype xfs --size 1024 --asprimary --ondisk vda
part /boot/efi --fstype vfat --size 512 --asprimary --ondisk vda
reqpart
part / --fstype="xfs" --ondisk=vda --maxsize=3000 --grow


%post --erroronfail
passwd -d root
passwd -l root

###
# Common Cloud Tweaks
###

# pvgrub support
echo -n "Creating grub.conf for pvgrub"
rootuuid=$( awk '$2=="/" { print $1 };'  /etc/fstab )
mkdir /boot/grub
echo -e 'default=0\ntimeout=0\n\n' > /boot/grub/grub.conf
for kv in $( ls -1v /boot/vmlinuz* |grep -v rescue |sed s/.*vmlinuz-//  ); do
  echo "title Rocky Linux 8 ($kv)" >> /boot/grub/grub.conf
  echo -e "\troot (hd0)" >> /boot/grub/grub.conf
  echo -e "\tkernel /boot/vmlinuz-$kv ro root=$rootuuid console=hvc0 LANG=en_US.UTF-8" >> /boot/grub/grub.conf
  echo -e "\tinitrd /boot/initramfs-$kv.img" >> /boot/grub/grub.conf
  echo
done
ln -sf grub.conf /boot/grub/menu.lst
ln -sf /boot/grub/grub.conf /etc/grub.conf

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

###
# Networking Changes
###

# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
USERCTL=no
PEERDNS=yes
IPV6INIT=no
NM_CONTROLLED=yes
IPV4_DHCP_TIMEOUT=300
EOF

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
echo > /etc/resolv.conf

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .


###
# Services
###

systemctl mask tmp.mount

###
# azure
###
# Setup WALinux Agent
dnf -y install WALinuxAgent
systemctl enable waagent

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

###
# Kernel and Drivers
###

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
echo -e 'rocky\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers
sed -i 's/name: cloud-user/name: rocky/g' /etc/cloud/cloud.cfg

dnf clean all

# XXX instance type markers - MUST match Rocky Infra expectation
echo 'azure' > /etc/yum/vars/infra

# change dhcp client retry/timeouts to resolve #6866


###
# Cleanup
###

###
# Azure Cleanup
###
sudo rm -f /var/log/waagent.log
sudo cloud-init clean
waagent -force -deprovision+user


# Commont cleanup
rm -f ~/.bash_history
export HISTSIZE=0

rm -f /var/lib/systemd/random-seed
rm -rf /root/anaconda-ks.cfg
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf /var/lib/yum/*
rm -rf /var/log/anaconda*
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

%packages
@core
chrony
dnf
yum
cloud-init
cloud-utils-growpart
NetworkManager
dracut-config-generic
dracut-norescue
firewalld
gdisk
grub2
kernel
nfs-utils
rsync
tar
dnf-utils
yum-utils
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-ivtv-firmware
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
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
-biosdevname
-iprutils
-plymouth

python3-jsonschema
qemu-guest-agent
dhcp-client
cockpit-ws
cockpit-system
-langpacks-*
-langpacks-en

rocky-release
rng-tools

WALinuxAgent
hyperv-daemons

%end
