# xfce
%packages

# these aren't an epel 8 thing for some reason.
@xfce-desktop
#@^xfce-desktop-environment
#@xfce-apps
#@xfce-extra-plugins
#@xfce-media
#@xfce-office

# Manual install...
geany
gparted
mousepad
ristretto
seahorse
transmission
pcp-selinux
#lightdm
#gdm
-gdm
-gnome-shell
-gnome-menus

xfce4-about
xfce4-appfinder
xfce4-taskmanager
xfce4-pulseaudio-plugin
xfce4-battery-plugin
xfce4-datetime-plugin
xfce4-netload-plugin
xfce4-places-plugin
xfce4-screenshooter-plugin
xfce4-smartbookmark-plugin
xfce4-systemload-plugin
xfce4-time-out-plugin
xfce4-weather-plugin
xfce4-whiskermenu-plugin
xfdashboard
xfdashboard-themes
pavucontrol

wget

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
