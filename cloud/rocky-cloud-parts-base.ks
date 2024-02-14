#zerombr
#clearpart --all --initlabel --disklabel=gpt
#reqpart
# This should allow BIOS, UEFI, and PReP booting. Trying to be as universal as
# possible. This is a similar setup to Fedora without the btrfs.
part /boot/efi --size=100  --fstype=efi      --asprimary
part /boot     --size=1000 --fstype=xfs      --label=boot
part prepboot  --size=4    --fstype=prepboot --asprimary
part biosboot  --size=1    --fstype=biosboot --asprimary
part /         --size=8000 --fstype="xfs"    --mkfsoptions "-m bigtime=0,inobtcount=0"

%pre
# Clear the Master Boot Record
dd if=/dev/zero of=/dev/vda bs=512 count=1
# Create a new GPT partition table
parted /dev/vda mklabel gpt
# Create a partition for /boot/efi
parted /dev/vda mkpart primary fat32 1MiB 100MiB
parted /dev/vda set 1 boot on
# Create a partition for /boot
parted /dev/vda mkpart primary xfs 100MiB 1100MiB
# Create a partition for prep
parted /dev/vda mkpart primary 1100MiB 1104MiB
# Create a partition for bios_grub
parted /dev/vda mkpart primary 1104MiB 1105MiB
# Create a partition for LVM
parted /dev/vda mkpart primary xfs 1106MiB 10.7GB

%end
