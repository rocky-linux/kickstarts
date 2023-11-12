# xfce
%packages

# these aren't an epel thing for some reason.
@xfce-desktop --nodefaults
#@^xfce-desktop-environment
#@xfce-apps
#@xfce-extra-plugins
#@xfce-media
#@xfce-office

# Manual install...
#geany
gparted
#mousepad
#ristretto
seahorse
#transmission
pcp-selinux
lightdm
#gdm
-gdm
-gnome-shell

# Some stuff might already be here, doesn't hurt to list it.
firefox
thunderbird
firewall-config
#pidgin
rocky-backgrounds
rocky-release
gparted
#rhythmbox

# extras
f35-backgrounds-xfce
f35-backgrounds-extras-xfce
f36-backgrounds-xfce
f36-backgrounds-extras-xfce
f37-backgrounds-xfce
f37-backgrounds-extras-xfce

xfce4-about
xfce4-taskmanager
#xfce4-battery-plugin
xfce4-datetime-plugin
xfce4-netload-plugin
#xfce4-places-plugin
xfce4-screenshooter-plugin
xfce4-smartbookmark-plugin
xfce4-systemload-plugin
xfce4-time-out-plugin
xfce4-weather-plugin
xfce4-whiskermenu-plugin
#xfdashboard
#xfdashboard-themes
pavucontrol

# XFCE group defaults
xfce4-appfinder
xfce4-power-manager
#xfce4-pulseaudio-plugin
xfce4-screensaver
xfce4-terminal
network-manager-applet
openssh-askpass
thunar-archive-plugin
thunar-volman
tumbler
xfce-polkit

wget
xdg-user-dirs
xdg-user-dirs-gtk

# save some space
-autofs
-acpid
-gimp-help
-desktop-backgrounds-basic
-aspell-*
-xfce4-sensors-plugin
-xfce4-eyes-plugin

### MINIMIZATION
-mpage
-hplip
-isdn4k-utils
-xsane
-xsane-gimp
-sane-backends

%end
