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
