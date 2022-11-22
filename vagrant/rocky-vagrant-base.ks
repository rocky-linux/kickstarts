url --url https://download.rockylinux.org/stg/rocky/8/BaseOS/$basearch/os/
repo --name=plus --baseurl=http://dl.rockylinux.org/pub/rocky/8/plus/$basearch/os

text
keyboard --vckeymap us
lang en_US
skipx
network  --bootproto=dhcp --device=link --activate --onboot=on
rootpw --plaintext vagrant
firewall --disabled
timezone --utc UTC
services --enabled=vmtoolsd
# The biosdevname and ifnames options ensure we get "eth0" as our interface
# even in environments like virtualbox that emulate a real NW card
bootloader --timeout=1 --append="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop"
zerombr
clearpart --all --initlabel
reqpart
part / --fstype=xfs --asprimary --size=1024 --grow

user --name=vagrant --plaintext --password=vagrant

shutdown
%addon com_redhat_kdump --disable
%end
