%include rocky-cloud-base.ks
%include rocky-cloud-parts-lvm.ks
%include rocky-cloud-ocp-packages.ks

repo --name "sig-cloud-common" --baseurl=http://dl.rockylinux.org/stg/sig/9/cloud/$basearch/cloud-common/ --includepkgs="oci-utils,python3-circuitbreaker,python3-daemon,python3-sdnotify,python39-oci-sdk" --cost=100
repo --name "extras" --baseurl=http://dl.rockylinux.org/stg/rocky/9/extras/$basearch/os/
repo --name=epel --cost=200 --baseurl=https://dl.fedoraproject.org/pub/epel/9/Everything/$basearch/

bootloader --append="console=ttyS0,115200n8 console=tty0 no_timer_check crashkernel=auto net.ifnames=0 LANG=en_US.UTF-8 transparent_hugepage=never rd.luks=0 rd.md=0 rd.dm=0 rd.lvm.vg=rocky rd.lvm.lv=rocky/root rd.net.timeout.dhcp=10" --location=mbr --timeout=1 --boot-drive=vda

%post --erroronfail

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
sed -i '1i # Modified for cloud image' /etc/cloud/cloud.cfg
echo -e 'rocky\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers
sed -i 's/name: cloud-user/name: rocky/g' /etc/cloud/cloud.cfg

# disable cloud kernel repo as it's not needed
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/Rocky-SIG-Cloud-Kernel.repo

dnf clean all

# XXX instance type markers - MUST match Rocky Infra expectation
echo 'oci' > /etc/yum/vars/infra

# change dhcp client retry/timeouts to resolve #6866
cat  >> /etc/dhcp/dhclient.conf << EOF

timeout 300;
retry 60;
EOF

# OCI - Import repo GPG key
cat <<EOF > /tmp/key
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
4QrtLe//99hXPcFVanIxgkdslnyYf4fjdbdlmNY=
=xpaH
-----END PGP PUBLIC KEY BLOCK-----
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
RgwnCPfIai7lLNx95bdwB8U2NpY11OXsoTLZAA==
=UWTf
-----END PGP PUBLIC KEY BLOCK-----
EOF

rpm --import /tmp/key


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

# OCI - Need iscsi as a dracut module
echo 'add_dracutmodules+=" iscsi "' > /etc/dracut.conf.d/iscsi.conf

# OCI - Virtio drivers
echo 'add_drivers+=" virtio virtio_blk virtio_net virtio_pci virtio_ring virtio_scsi virtio_console "' > /etc/dracut.conf.d/virtio.conf

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
if [ -d $DRACUT_CFG  ]; then
    FILE_COUNT=`ls $DRACUT_CFG | wc -l`
    if [ $FILE_COUNT -eq 0  ]; then
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
            if [ ! -e $cicfg  ]; then
                echo "$(date) - Creating symlink from $dcfg to $cicfg."
                ln -s $dcfg $cicfg
            fi
        done
    fi
fi

echo "$(date) - OCI initramfs network modification script done."


true

%end
