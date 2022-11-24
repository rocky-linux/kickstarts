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
#reqpart
part biosboot  --size=1    --fstype=biosboot --asprimary
part /boot/efi --size=100  --fstype=efi      --asprimary
part /boot     --size=1000 --fstype=xfs      --asprimary --label=boot
part /         --size=8000 --fstype="xfs"    --mkfsoptions "-m bigtime=0,inobtcount=0"

user --name=vagrant --plaintext --password=vagrant
url --url https://download.rockylinux.org/stg/rocky/9/BaseOS/$basearch/os/
%addon com_redhat_kdump --disable
%end
