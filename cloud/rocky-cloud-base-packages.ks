%packages
@core
rocky-release
dnf
kernel
yum
nfs-utils
dnf-utils
hostname
-aic94xx-firmware
-alsa-firmware
-alsa-lib
-alsa-tools-firmware
-ivtv-firmware
-iwl1000-firmware
-iwl100-firmware
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
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-libertas-sd8686-firmware
-libertas-sd8787-firmware
-libertas-usb8388-firmware

cloud-init
cloud-utils-growpart
python3-jsonschema
dracut-config-generic
-dracut-config-rescue
firewalld

# some stuff that's missing from core or things we want
tar
tcpdump
rsync
rng-tools
cockpit-ws
cockpit-system
qemu-guest-agent
virt-what

-biosdevname
-plymouth
-iprutils
# Fixes an s390x issue
#-langpacks-*
-langpacks-en
%end
