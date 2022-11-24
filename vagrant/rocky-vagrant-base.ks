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
clearpart --all --initlabel --disklabel=gpt
part biosboot  --size=1    --fstype=biosboot --asprimary
part /boot/efi --size=100  --fstype=efi      --asprimary
part /boot     --size=1000 --fstype=xfs      --label=boot
part /         --size=8000 --fstype="xfs"    --mkfsoptions "-m bigtime=0,inobtcount=0" --grow
user --name=vagrant --plaintext --password=vagrant

shutdown
%addon com_redhat_kdump --disable
%end
