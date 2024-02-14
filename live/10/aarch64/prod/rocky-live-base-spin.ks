# rocky-live-base-spin.ks
#
# Base installation information for Rocky Linux images
# Contains EPEL.
#

lang en_US.UTF-8
keyboard us
timezone US/Eastern
selinux --enforcing
firewall --enabled --service=mdns
xconfig --startxonboot
zerombr
clearpart --all
part / --size 5120 --fstype ext4
services --enabled=NetworkManager,ModemManager --disabled=sshd
network --bootproto=dhcp --device=link --activate
rootpw --lock --iscrypted locked
shutdown

%include rocky-repo-epel.ks

%packages
@base-x
@guest-desktop-agents
@standard
@core
@fonts
@input-methods
@dial-up
@multimedia
@hardware-support

# explicit
kernel
kernel-modules
kernel-modules-extra
#memtest86+
anaconda
anaconda-install-env-deps
anaconda-live
@anaconda-tools
efi-filesystem
efivar-libs
efibootmgr
grub2-common
grub2-efi-*64
grub2-efi-*64-cdboot
#grub2-pc-modules
grub2-tools
#grub2-tools-efi
grub2-tools-extra
grub2-tools-minimal
grubby
shim-*64
-shim-unsigned-*64
-fcoe-utils

# Required for SVG rnotes images
aajohan-comfortaa-fonts

# RHBZ#1242586 - Required for initramfs creation
dracut-live
#syslinux

# Anaconda needs all the locales available, just like a DVD installer
glibc-all-langpacks

# adapted from fedora
livesys-scripts

# absolutely required - don't want a system that can't actually update
epel-release
%end

%post
systemctl enable livesys.service
systemctl enable livesys-late.service
systemctl enable tmp.mount

cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# fix packagekit
rm -f /var/lib/rpm/__db*
echo "Packages within this LiveCD"
rpm -qa --qf '%{size}\t%{name}-%{version}-%{release}.%{arch}\n' |sort -rn
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# convince readahead not to collect
# FIXME: for systemd
echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs, we don't need them on the live media itself.
# See bug 1317709
rm -f /boot/*-rescue*

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794
systemctl disable network

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

%end
