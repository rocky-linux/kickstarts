# This is a minimal Rocky kickstart designed for docker.
# It will not produce a bootable system
# To use this kickstart, run the following command
# livemedia-creator --make-tar \
#   --iso=/path/to/boot.iso  \
#   --ks=rocky-8.ks \
#   --image-name=rocky-root.tar.xz
#

# Basic setup information

url --url https://dl.rockylinux.org/pub/rocky/8/BaseOS/$basearch/os/

bootloader --disable
firewall --disabled
network --bootproto=dhcp --device=link --activate --onboot=on
rootpw --lock --iscrypted locked
selinux --enforcing
shutdown

keyboard us
lang en_US.UTF-8
timezone --isUtc --nontp UTC

# Disk setup
zerombr
clearpart --all --initlabel
autopart --noboot --nohome --noswap --nolvm --fstype=ext4

# Package setup
%packages --excludedocs --instLangs=en --nocore --excludeWeakdeps
bash
binutils
coreutils-single
glibc-minimal-langpack
hostname
iputils
less
rocky-release
rootfiles
tar
vim-minimal
yum

-brotli
-dosfstools
-dracut
-e2fsprogs
-firewalld
-fuse-libs
-gettext*
-gnupg2-smime
-grub\*
-iptables
-kernel
-libss
-os-prober*
-pinentry
-qemu-guest-agent
-shared-mime-info
-trousers
-xfsprogs
-xkeyboard-config
%end

%post --erroronfail --log=/root/anaconda-post.log
# container customizations inside the chroot

echo 'container' > /etc/dnf/vars/infra

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

# Limit languages to help reduce size.
LANG="en_US"
echo "%_install_langs $LANG" > /etc/rpm/macros.image-language-conf


# systemd fixes
:> /etc/machine-id
umount /run
systemd-tmpfiles --create --boot
# mask mounts and login bits
systemctl mask systemd-logind.service getty.target console-getty.service sys-fs-fuse-connections.mount systemd-remount-fs.service dev-hugepages.mount

# Remove things we don't need
rm -f /etc/udev/hwdb.bin
rm -rf /usr/lib/udev/hwdb.d/
rm -rf /boot
rm -rf /var/lib/dnf/history.*


%end
