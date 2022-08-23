# inherited from Fedora kickstarts F35 with minor changes

%packages
# install env-group to resolve RhBug:1891500
@^mate-desktop-environment

compiz
compiz-plugins-main
compiz-plugins-extra
compiz-manager
compizconfig-python
compiz-plugins-experimental
libcompizconfig
compiz-plugins-main
ccsm
simple-ccsm
emerald-themes
emerald
fusion-icon

# blacklist applications which breaks mate-desktop
-audacious

# see https://bugzilla.redhat.com/show_bug.cgi?id=2068699
# and https://bugzilla.redhat.com/show_bug.cgi?id=1933494
# use earlyoom instead of systemd-oomd-defaults
#earlyoom
#-systemd-oomd-defaults

# libreoffice
libreoffice-calc
#libreoffice-emailmerge
libreoffice-graphicfilter
libreoffice-impress
libreoffice-writer

# FIXME; apparently the glibc maintainers dislike this, but it got put into the
# desktop image at some point.  We won't touch this one for now.
nss-mdns

# Drop things for size
-@3d-printing
-@admin-tools
-brasero
-fedora-icon-theme
-gnome-icon-theme
-gnome-icon-theme-symbolic
-gnome-logs
-gnome-software
-gnome-user-docs

-@mate-applications

# Help and art can be big, too
-gnome-user-docs
-evolution-help

# Legacy cmdline things we don't want
-telnet

%end
