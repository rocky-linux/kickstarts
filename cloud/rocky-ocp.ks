%include rocky-cloud-base.ks
%include rocky-cloud-parts-lvm.ks
%include rocky-cloud-ocp-packages.ks

bootloader --append="console=ttyS0,115200n8 console=tty0 no_timer_check crashkernel=auto net.ifnames=0 LANG=en_US.UTF-8 transparent_hugepage=never rd.luks=0 rd.md=0 rd.dm=0 rd.lvm.vg=rocky rd.lvm.lv=rocky/root rd.net.timeout.dhcp=10" --location=mbr --timeout=1 --boot-drive=vda
repo --name="oraclelinux-addons" --baseurl=http://yum.oracle.com/repo/OracleLinux/OL8/addons/$basearch/ --install --includepkgs="oci-utils"

%post --erroronfail
# Attempting to force legacy BIOS boot if we boot from UEFI
# This was backported from our 9 kickstarts to address some issues.
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
Version: GnuPG v2.0.14 (GNU/Linux)

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
=dTZ0
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

# OCI - Start ocid on boot
systemctl enable ocid.service

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
