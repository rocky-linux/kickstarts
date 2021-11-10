
%packages
# install env-group to resolve RhBug:1891500
@^kde-desktop-environment

@firefox
@kde-apps
@kde-media

# Libreoffice
libreoffice-calc
libreoffice-emailmerge
libreoffice-graphicfilter
libreoffice-impress
libreoffice-writer

-@admin-tools

### The KDE-Desktop

### fixes
sddm

# use kde-print-manager instead of system-config-printer
-system-config-printer
# make sure mariadb lands instead of MySQL (hopefully a temporary hack)
mariadb-embedded
mariadb-connector-c
mariadb-server

# minimal localization support - allows installing the kde-l10n-* packages
#system-config-language <- Not in EL8
#kde-l10n <- Not in EL8

# unwanted packages from @kde-desktop
# don't include these for now to fit on a cd
-desktop-backgrounds-basic
-kdeaccessibility*
-ktorrent			# kget has also basic torrent features (~3 megs)
-digikam			# digikam has duplicate functionality with gwenview (~28 megs)
-kipi-plugins			# ~8 megs + drags in Marble
-krusader			# ~4 megs
-k3b				# ~15 megs

#-kdeplasma-addons		# ~16 megs

# Additional packages that are not default in kde-* groups, but useful
#kdeartwork			# only include some parts of kdeartwork
fuse
#mediawriter <-- Not in EL8

### space issues

# admin-tools
-gnome-disk-utility
# kcm_clock still lacks some features, so keep system-config-date around
#-system-config-date
# prefer kcm_systemd
-system-config-services
# prefer/use kusers
-system-config-users

# we need to keep epel-release, otherwise we can't update
epel-release

### MINIMIZATION ###
-mpage
-hplip
-isdn4k-utils
-xsane
-xsane-gimp
-@input-methods
-scim*
-iok

%end

