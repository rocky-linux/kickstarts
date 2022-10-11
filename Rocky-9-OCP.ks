text
repo --name="BaseOS" --baseurl=http://dl.rockylinux.org/pub/rocky/9/BaseOS/$basearch/os/
repo --name="AppStream" --baseurl=http://dl.rockylinux.org/pub/rocky/9/AppStream/$basearch/os/
repo --name="oraclelinux-addons" --baseurl=http://yum.oracle.com/repo/OracleLinux/OL9/addons/$basearch/ --install --includepkgs="oci-utils"

url --url http://dl.rockylinux.org/pub/rocky/9/BaseOS/$basearch/os/

auth --enableshadow --passalgo=sha512
reboot
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
rootpw --plaintext rocky
selinux --enforcing
services --disabled="kdump" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd"
timezone UTC --isUtc
# Disk
bootloader --append="console=ttyS0,115200n8 console=tty0 no_timer_check crashkernel=auto net.ifnames=0 LANG=en_US.UTF-8 transparent_hugepage=never rd.luks=0 rd.md=0 rd.dm=0 rd.lvm.vg=rocky rd.lvm.lv=rocky/root rd.net.timeout.dhcp=10" --location=mbr --timeout=1 --boot-drive=vda

clearpart --all --initlabel --drives vda
part /boot --fstype xfs --size 1024 --asprimary --ondisk vda
part /boot/efi --fstype vfat --size 512 --asprimary --ondisk vda

part pv.01 --ondisk=vda --size=1 --grow --asprimary
volgroup rocky pv.01
logvol / --vgname=rocky --size=3000 --name=root --grow

%post --erroronfail

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

# Remove build-time resolvers to fix #16948
echo > /etc/resolv.conf

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

echo "virtual-guest" > /etc/tuned/active_profile

# generic localhost names
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

EOF
echo .

systemctl mask tmp.mount

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
echo 'oci' > /etc/yum/vars/infra

# change dhcp client retry/timeouts to resolve #6866
cat  >> /etc/dhcp/dhclient.conf << EOF

timeout 300;
retry 60;
EOF


rm -rf /var/log/yum.log
rm -rf "/var/lib/yum/*"
rm -rf /root/install.log
rm -rf /root/install.log.syslog
rm -rf /root/anaconda-ks.cfg
rm -rf /var/log/anaconda*

rm -f /var/lib/systemd/random-seed

cat /dev/null > /etc/machine-id

echo "Fixing SELinux contexts."
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

# remove these for debugging
sed -i -e 's/ rhgb quiet//' /boot/grub/grub.conf

# enable resizing on copied AMIs
echo 'install_items+=" sgdisk "' > /etc/dracut.conf.d/sgdisk.conf


# OCI - Start ocid on boot
systemctl enable ocid.service

# OCI - Need iscsi as a dracut module
echo 'add_dracutmodules+="iscsi"' > /etc/dracut.conf.d/iscsi.conf

# OCI - Virtio drivers
echo 'add_drivers+="virtio virtio_blk virtio_net virtio_pci virtio_ring virtio_scsi virtio_console"' > /etc/dracut.conf.d/virtio.conf

# OCI - YOLO
mkdir -p /usr/lib/dracut/modules.d/95oci
OCIDRACUT="H4sIAGtFHmMAA+2WWW/bOBCA/Vr+illZzQXoluPUhgMURYrmpS02fevuGpJIWYQVUiWpJoHr/15S
crLZZBs3QA8U5QfYosQ5NUNSrRRBTfMAi6xoVXDOcVsT6ePg2YgXNBh8C0LNeDTqrpq7124cpfF4
nIzT8fhwEEaj+HA8gNE38b6FVqpMAAwE5+ohuW3zvyjtw/UnLMtr4lFZSOrlV00mpS+rR/rYUv84
StJBlIx10ZNREscD/SRNkwGE3yXjO/zm9R/+EeSUBbJCQ/AOPNANQCYgK1LXniwEbdQUKMOEKU9l
ufT6eUbrqRby8kzSwuNlKYmaQDo1JrQhcjkBJWdHIC9mKUg9TIEoKGlN1FVDZtobGr7NVFFB11nm
3YLikNU1v4A8ozXwVgEtQVUEullM5RKKjGkZQTJ8BTmBkrcMo6Eg5QTeiCxvFxMYJmESxWGYImRc
wYLo8i7gOMDkY8Dauob4eCeCT5/Ah1uN7+mhbmx0+vrs5M93s10kZo67Mp6Hec2L5WTtIB1Oby3n
vIYQBPa76P1+XcDODrwHj4DjCgf+nprYGSDQlFwA69KgDNy93ooERpR5uD8FzDs5w3utv+qEnz6d
HKwdmIHTudE2TdgFZ4qyltwodGk2mZBk3snNO0dfTlh7vc722sQ9bcftInCMmiCqFQyiG+lN2HPC
ipm7J5WYC9LUWUH+VXMC/fsrLp39TgtzRuAe3RQpKr5JcAJnS9o0lC3AveXD930HjnfiR4lDl/7y
XC5uqUkjT7CZdgJ13gSdHbP+FcHebSNOr3VJFYSopGgXfWX1S21ZmgV109c3rYCuwzgxe6oJ+/Ts
xdkpbPR5oyhn15l+leR/kuw13L6BdeFAEgwehd3gn7fP372a+QdusBK9ilSYmniq9RTc1eU0MBKB
HnwI11P9n6x3/ycP3QsXme4E56VeoNr4g9GZt/az9zbLdrac//29p7f3tnn8wb9h2/dfchjdOf/D
OIns+f8j2Jz/+iD/4V8ARUWK5d4+rNCTzRkTojVCmDSEYXl/gjJdqrruJ8zNvOJ8CY0gXqt3NTg6
0vufjg5T8YXvVkeb+dkv3GKxWCwWi8VisVgsFovFYrFYLBaLxWL5jnwGdMMrBgAoAAA="

base64 -d <<<"$OCIDRACUT" | tar -xz

OCICLOUDCFG="IyBPQ0kgY2xvdWQtaW5pdCBjb25maWd1cmF0aW9uCmRhdGFzb3VyY2VfbGlzdDogWydPcmFjbGUn
LCAnT3BlblN0YWNrJ10KZGF0YXNvdXJjZToKICBPcGVuU3RhY2s6CiAgICBtZXRhZGF0YV91cmxz
OiBbJ2h0dHA6Ly8xNjkuMjU0LjE2OS4yNTQnXQogICAgdGltZW91dDogMTAKICAgIG1heF93YWl0
OiAyMAoKIyBzd2FwIGZpbGUKc3dhcDoKICAgZmlsZW5hbWU6IC8uc3dhcGZpbGUKICAgc2l6ZTog
ImF1dG8iCgpjbG91ZF9pbml0X21vZHVsZXM6CiMgT0NJOiBkaXNrX3NldHVwIGlzIGRpc2FibGVk
CiMtIGRpc2tfc2V0dXAKIC0gbWlncmF0b3IKIC0gYm9vdGNtZAogLSB3cml0ZS1maWxlcwojIE9D
STogVGhlIGdyb3dwYXJ0IG1vZHVsZSBpcyBkaXNhYmxlZCBieSBkZWZhdWx0LiBUbyBlbmFibGUg
YXV0b21hdGljIGJvb3Qgdm9sdW1lIHJlc2l6aW5nLCB1bmNvbW1lbnQKIyB0aGUgYmVsb3cgZW50
cnkgZm9yICctIGdyb3dwYXJ0JyBhbmQgcmVib290LiBBbGwgdGhlIGRlcGVuZGVudCBwYWNrYWdl
cyBmb3IgdGhlIGdyb3dwYXJ0CiMgbW9kdWxlIHRvIHdvcmsgc3VjaCBhcyBjbG91ZC11dGlscy1n
cm93cGFydCBhbmQgZ2Rpc2sgYXJlIGFscmVhZHkgaW5jbHVkZWQgaW4gdGhlIGltYWdlLgojLSBn
cm93cGFydAogLSByZXNpemVmcwojIE9DSTogc2V0X2hvc3RuYW1lLCB1cGRhdGVfaG9zdG5hbWUs
IHVwZGF0ZV9ldGNfaG9zdHMgYXJlIGRpc2FibGVkCiMtIHNldF9ob3N0bmFtZQojLSB1cGRhdGVf
aG9zdG5hbWUKIy0gdXBkYXRlX2V0Y19ob3N0cwogLSByc3lzbG9nCiAtIHVzZXJzLWdyb3Vwcwog
LSBzc2gKCmNsb3VkX2NvbmZpZ19tb2R1bGVzOgogLSBtb3VudHMKIC0gbG9jYWxlCiAtIHNldC1w
YXNzd29yZHMKIyBPQ0k6IHJoX3N1YnNjcmlwdGlvbiBpcyBkaXNhYmxlZAojLSByaF9zdWJzY3Jp
cHRpb24KIC0geXVtLWFkZC1yZXBvCiAtIHBhY2thZ2UtdXBkYXRlLXVwZ3JhZGUtaW5zdGFsbAog
LSB0aW1lem9uZQogLSBudHAKIC0gcHVwcGV0CiAtIGNoZWYKIC0gc2FsdC1taW5pb24KIC0gbWNv
bGxlY3RpdmUKIC0gZGlzYWJsZS1lYzItbWV0YWRhdGEKIC0gcnVuY21kCgpjbG91ZF9maW5hbF9t
b2R1bGVzOgogLSByaWdodHNjYWxlX3VzZXJkYXRhCiAtIHNjcmlwdHMtcGVyLW9uY2UKIC0gc2Ny
aXB0cy1wZXItYm9vdAogLSBzY3JpcHRzLXBlci1pbnN0YW5jZQogLSBzY3JpcHRzLXVzZXIKIC0g
c3NoLWF1dGhrZXktZmluZ2VycHJpbnRzCiAtIGtleXMtdG8tY29uc29sZQogLSBwaG9uZS1ob21l
CiAtIGZpbmFsLW1lc3NhZ2UKIyBPQ0k6IHBvd2VyLXN0YXRlLWNoYW5nZSBpcyBkaXNhYmxlZAoj
LSBwb3dlci1zdGF0ZS1jaGFuZ2UKCg=="

base64 -d <<<"$OCICLOUDCFG" >> /etc/cloud/cloud.cfg.d/99_oci.cfg

# Rerun dracut for the installed kernel (not the running kernel):
KERNEL_VERSION=$(rpm -q kernel --qf '%%{V}-%%{R}.%%{arch}\n')
dracut -f /boot/initramfs-$KERNEL_VERSION.img $KERNEL_VERSION

# OCI needs Iscsi
grubby --args="libiscsi.debug_libiscsi_eh=1 netroot=iscsi:169.254.0.2:::1:iqn.2015-02.oracle.boot:uefi ip=dhcp rd.iscsi.bypass rd.iscsi.param=node.session.timeo.replacement_timeout=6000" --update-kernel "/boot/vmlinuz-$KERNEL_VERSION"

passwd -d root
passwd -l root

# Copyright (C) 2020 Oracle Corp., Inc.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
#
# /usr/lib/oci-linux-config/cloud/scripts/initramfs-mod/net.sh
#

echo "$(date) - OCI initramfs network modification script started."

# Symlink network config files where cloud-init >= 19.4 expects them
DRACUT_CFG=/run/initramfs/state/etc/sysconfig/network-scripts
CI_DIR=/run
if [ -d $DRACUT_CFG ]; then
    FILE_COUNT=`ls $DRACUT_CFG | wc -l`
    if [ $FILE_COUNT -eq 0 ]; then
        # Create dummy file if dracut did not create network device config
        dummycfg=$CI_DIR/net-dummy.conf
        echo "DEVICE=\"dummy\"" > $dummycfg
        echo "BOOTPROTO=dhcp" >> $dummycfg
        echo "$(date) - Creating dummy config $dummycfg."
    else
        for dcfg in $DRACUT_CFG/*; do
            filename=${dcfg##*/}
            devname=${filename##ifcfg-}
            cicfg=$CI_DIR/net-$devname.conf
            if [ ! -e $cicfg ]; then
                echo "$(date) - Creating symlink from $dcfg to $cicfg."
                ln -s $dcfg $cicfg
            fi
        done
    fi
fi

echo "$(date) - OCI initramfs network modification script done."
true

%end

%packages
@core
chrony
cloud-init
cloud-utils-growpart
cockpit-system
cockpit-ws
dhcp-client
dnf
dnf-utils
dracut-config-generic
firewalld
gdisk
grub2
iscsi-initiator-utils
kernel
NetworkManager
nfs-utils
oci-utils
python3-jsonschema
qemu-guest-agent
rng-tools
rocky-release
rsync
tar
yum
yum-utils

-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-biosdevname
-iprutils
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
-langpacks-*
-langpacks-en
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware
-plymouth
%end

