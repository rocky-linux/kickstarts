zerombr
clearpart --all --initlabel --disklabel=gpt
#reqpart
# This should allow BIOS, UEFI, and PReP booting. Trying to be as universal as
# possible. This is a similar setup to Fedora without the btrfs.
part prepboot  --size=4    --fstype=prepboot --asprimary
part biosboot  --size=1    --fstype=biosboot --asprimary
part /boot/efi --size=100  --fstype=efi      --asprimary
part /boot     --size=1000 --fstype=xfs      --label=boot
part /         --size=8000 --fstype="xfs"    --mkfsoptions "-m bigtime=0,inobtcount=0"
