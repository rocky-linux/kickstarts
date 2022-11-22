%packages --instLangs=en
bash-completion
man-pages
bzip2
rsync
nfs-utils
cifs-utils
chrony
yum-utils
open-vm-tools
# Vagrant boxes aren't normally visible, no need for Plymouth
-plymouth
# Microcode updates cannot work in a VM
-microcode_ctl
# Firmware packages are not needed in a VM
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6050-firmware
-iwl7260-firmware
# Don't build rescue initramfs
-dracut-config-rescue
%end
