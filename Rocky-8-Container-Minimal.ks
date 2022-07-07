# This is a minimal Rocky kickstart designed for docker.
# It will not produce a bootable system
# To use this kickstart, run make

# Basic setup information
url --url https://dl.rockylinux.org/stg/rocky/8/BaseOS/$basearch/os/

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

# Package setup
%packages --ignoremissing --excludedocs --instLangs=en --nocore --excludeWeakdeps
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

# Cleanup the image
rm -f /etc/udev/hwdb.bin
rm -rf /usr/lib/udev/hwdb.d/ \
       /boot /var/lib/dnf/history.* \
      "/tmp/*" "/tmp/.*" || true

%end