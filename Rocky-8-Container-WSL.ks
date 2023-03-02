# This is a minimal Rocky kickstart designed for docker.
# It will not produce a bootable system
# To use this kickstart, run make

# Basic setup information
url --url https://download.rockylinux.org/stg/rocky/8/BaseOS/$basearch/os/

text
bootloader --disable
firewall --disabled
network --bootproto=dhcp --device=link --activate --onboot=on
rootpw --lock --iscrypted locked
selinux --disabled
shutdown

keyboard us
lang en_US.UTF-8
timezone --isUtc --nontp UTC

# Disk setup
zerombr
clearpart --all --initlabel
autopart --noboot --nohome --noswap --nolvm --fstype=ext4

%pre
dbus-broker-launch --scope=none
%end
%addon com_redhat_kdump --disable
%end

# Package setup
%packages --ignoremissing --excludedocs --instLangs=en --nocore --excludeWeakdeps
bash
binutils
coreutils-single
glibc-minimal-langpack
hostname
iputils # this pulls in systemd, lets ask for it by name, too
less
passwd
rocky-release
rootfiles
tar
vim-minimal
yum

-brotli
-dosfstools
-kexec-tools
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

# Stay compatible
echo 'container' > /etc/dnf/vars/infra

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

# Limit languages to help reduce size.
LANG="en_US"
echo "%_install_langs $LANG" > /etc/rpm/macros.image-language-conf

# https://bugzilla.redhat.com/show_bug.cgi?id=1727489
echo 'LANG="C.UTF-8"' >  /etc/locale.conf

# systemd fixes
:> /etc/machine-id
umount /run
systemd-tmpfiles --create --boot

# mask mounts and login bits
systemctl mask \
    console-getty.service \
    dev-hugepages.mount \
    getty.target \
    sys-fs-fuse-connections.mount \
    systemd-logind.service \
    systemd-remount-fs.service

# Cleanup the image
rm -f /etc/udev/hwdb.bin
rm -rf /usr/lib/udev/hwdb.d/ \
       /boot /var/lib/dnf/history.* \
       /tmp/* /tmp/.* || true

%end
