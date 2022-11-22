zerombr
clearpart --all --initlabel --disklabel=gpt
#reqpart
# This should allow BIOS, UEFI, and PReP booting. Trying to be as universal as
# possible. This is a similar setup to Fedora without the btrfs.
part prepboot  --size=4    --fstype=prepboot --asprimary
part biosboot  --size=1    --fstype=biosboot --asprimary
part /boot/efi --size=100  --fstype=efi      --asprimary
part /boot     --size=1000 --fstype=xfs      --asprimary --label=boot
part pv.01     --size=1    --ondisk=vda      --grow

volgroup rocky pv.01
logvol / --vgname=rocky --size=8000 --name=root --grow --mkfsoptions "-m bigtime=0,inobtcount=0"
