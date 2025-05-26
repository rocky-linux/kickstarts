# Maintained by RelEng

%include rocky-live-base-spin.ks
%include rocky-live-kde-common.ks

%post

sed -i 's/^livesys_session=.*/livesys_session="kde"/' /etc/sysconfig/livesys

# set default GTK+ theme for root (see #683855, #689070, #808062)
cat > /root/.gtkrc-2.0 << EOF
include "/usr/share/themes/Adwaita/gtk-2.0/gtkrc"
include "/etc/gtk-2.0/gtkrc"
gtk-theme-name="Adwaita"
EOF
mkdir -p /root/.config/gtk-3.0
cat > /root/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name = Adwaita
EOF

rm -f /usr/share/wallpapers/Fedora
ln -s rocky-abstract-2 /usr/share/wallpapers/Fedora

systemctl enable --force sddm.service
dnf config-manager --set-enabled crb

cat > /etc/sddm.conf.d/theme.conf <<THEMEEOF
[Theme]
Current=breeze
THEMEEOF

%end
