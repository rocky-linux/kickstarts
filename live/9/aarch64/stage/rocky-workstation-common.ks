%packages

# Exclude unwanted groups that rocky-live-base.ks pulls in
-@dial-up
-@input-methods
-@standard

# Make sure to sync any additions / removals done here with
# workstation-product-environment in comps
@base-x
@core
@fonts
@gnome-desktop
@guest-desktop-agents
@hardware-support
@internet-browser
@multimedia
@networkmanager-submodules
@workstation-product

# Libreoffice
libreoffice-calc
#libreoffice-emailmerge
libreoffice-graphicfilter
libreoffice-impress
libreoffice-writer

# Exclude unwanted packages from @anaconda-tools group
-gfs2-utils
-reiserfs-utils

%end
