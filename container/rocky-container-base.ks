%include rocky-container.ks

%packages --excludedocs --inst-langs=en --nocore --exclude-weakdeps
bash
binutils
coreutils-single
crypto-policies-scripts
curl-minimal
findutils
glibc-minimal-langpack
gzip
hostname
iputils
less
libcurl-minimal
libusbx
rocky-release
rootfiles
tar
usermode
util-linux
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
       "/tmp/*" "/tmp/.*" || true


%end
