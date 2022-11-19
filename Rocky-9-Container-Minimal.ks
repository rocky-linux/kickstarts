# This is a minimal Rocky kickstart designed for docker.
# It will not produce a bootable system
# To use this kickstart, run make

# Basic setup information

bootloader --disable
firewall --disabled
network --bootproto=dhcp --device=link --activate --onboot=on
rootpw --lock --iscrypted locked
selinux --disabled
shutdown

keyboard us
lang en_US.UTF-8
timezone --utc --nontp UTC

# Disk setup
zerombr
clearpart --all --initlabel
autopart --noboot --nohome --noswap --nolvm --fstype=ext4

# This breaks everything, apparently
%addon com_redhat_kdump --disable
%end

# Package setup
%packages --excludedocs --inst-langs=en --nocore --exclude-weakdeps
bash
coreutils-single
glibc-minimal-langpack
microdnf
rocky-release

-brotli
-dosfstools
-e2fsprogs
-firewalld
-fuse-libs
-gettext*
-gnupg2-smime
-grub\*
-hostname
-iptables
-iputils
-kernel
-kexec-tools
-less
-libss
-os-prober*
-pinentry
-qemu-guest-agent
-rootfiles
-shared-mime-info
-tar
-trousers
-vim-minimal
-xfsprogs
-xkeyboard-config
-yum
%end

%post --erroronfail --log=/root/anaconda-post.log
# container customizations inside the chroot


rpm --rebuilddb

/bin/date +%Y-%m-%d_%H:%M:%S > /etc/BUILDTIME

echo 'container' > /etc/dnf/vars/infra

LANG="en_US"
echo '%_install_langs en_US.UTF-8' > /etc/rpm/macros.image-language-conf
echo 'LANG="C.UTF-8"' >  /etc/locale.conf

rm -f /var/lib/dnf/history.* 
rm -fr "/var/log/*" "/tmp/*" "/tmp/.*"

for dir in $(ls -d "/usr/share/{locale,i18n}/*" | grep -v 'en_US\|all_languages\|locale\.alias'); do rm -fr $dir; done

# systemd fixes
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
