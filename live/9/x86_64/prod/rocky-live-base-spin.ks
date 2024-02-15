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
memtest86+
anaconda
anaconda-install-env-deps
anaconda-live
livesys-scripts
@anaconda-tools
efi-filesystem
efivar-libs
efibootmgr
grub2-common
grub2-efi-*64
grub2-efi-*64-cdboot
grub2-pc-modules
grub2-tools
grub2-tools-efi
grub2-tools-extra
grub2-tools-minimal
grubby
shim-*64
-shim-unsigned-*64

# Required for SVG rnotes images
aajohan-comfortaa-fonts

# RHBZ#1242586 - Required for initramfs creation
dracut-live
syslinux

# Anaconda needs all the locales available, just like a DVD installer
glibc-all-langpacks

# no longer in @core since 2018-10, but needed for livesys script
initscripts
chkconfig

# absolutely required - don't want a system that can't actually update
epel-release
%end

%post
systemctl enable livesys.service
systemctl enable livesys-late.service
# Enable tmpfs for /tmp - this is a good idea
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# PackageKit likes to play games. Let's fix that.
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' --whatprovides system-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
echo "Packages within this LiveCD"
rpm -qa
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
# fails due to RHBZ #1369794 - the error is expected
systemctl disable network

# Remove machine-id on generated images
rm -f /etc/machine-id
touch /etc/machine-id

# relabel
restorecon -R /

%end
%post --nochroot
# only works on x86_64
if [ "unknown" = "i386" -o "unknown" = "x86_64" ]; then
    # For livecd-creator builds. livemedia-creator is fine.
    if [ ! -d /LiveOS ]; then mkdir -p /LiveOS ; fi
    cp /usr/bin/livecd-iso-to-disk /LiveOS
fi

%end
