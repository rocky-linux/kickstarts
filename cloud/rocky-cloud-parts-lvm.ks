zerombr
clearpart --all --initlabel --disklabel=gpt
part biosboot  --size=1    --fstype=biosboot --asprimary
part /boot/efi --size=100  --fstype=efi      --asprimary
part /boot     --size=1000 --fstype=xfs      --asprimary --label=boot
part pv.01     --size=1    --ondisk=vda      --asprimary --grow
volgroup rocky pv.01
logvol / --vgname=rocky --size=8000 --name=root --grow
