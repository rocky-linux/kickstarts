# rocky-live-kde.ks
# BROKEN

%include rocky-live-base-spin.ks
%include rocky-live-xfce-common.ks

part / --size 6144

%post
# xfce configuration

# create /etc/sysconfig/desktop (needed for installation)

cat > /etc/sysconfig/desktop <<EOF
PREFERRED=/usr/bin/startxfce4
DISPLAYMANAGER=/usr/sbin/lightdm
EOF

cat >> /etc/rc.d/init.d/livesys << EOF

mkdir -p /home/liveuser/.config/xfce4
# ugly stuff, this should give us a default background for now
#mkdir -p /usr/share/backgrounds/images
#ln -s /usr/share/backgrounds/f32/default/f32.png \
#  /usr/share/backgrounds/images/default.png

cat > /home/liveuser/.config/xfce4/helpers.rc << FOE
MailReader=sylpheed-claws
FileManager=Thunar
WebBrowser=firefox
FOE

# disable screensaver locking (#674410)
cat >> /home/liveuser/.xscreensaver << FOE
mode:           off
lock:           False
dpmsEnabled:    False
FOE

# deactivate xfconf-migration (#683161)
rm -f /etc/xdg/autostart/xfconf-migration-4.6.desktop || :

# deactivate xfce4-panel first-run dialog (#693569)
mkdir -p /home/liveuser/.config/xfce4/xfconf/xfce-perchannel-xml
cp /etc/xdg/xfce4/panel/default.xml /home/liveuser/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml

# set up lightdm autologin
sed -i 's/^#autologin-user=.*/autologin-user=liveuser/' /etc/lightdm/lightdm.conf
sed -i 's/^#autologin-user-timeout=.*/autologin-user-timeout=0/' /etc/lightdm/lightdm.conf
sed -i 's/^#show-language-selector=.*/show-language-selector=true/' /etc/lightdm/lightdm-gtk-greeter.conf

# set Xfce as default session, otherwise login will fail
sed -i 's/^#user-session=.*/user-session=xfce/' /etc/lightdm/lightdm.conf

# debrand
#sed -i "s/Red Hat Enterprise/Rocky/g" /usr/share/anaconda/gnome/fedora-welcome.desktop
#sed -i "s/RHEL/Rocky Linux/g" /usr/share/anaconda/gnome/fedora-welcome
#sed -i "s/Red Hat Enterprise/Rocky/g" /usr/share/anaconda/gnome/fedora-welcome
#sed -i "s/org.fedoraproject.AnacondaInstaller/fedora-logo-icon/g" /usr/share/anaconda/gnome/fedora-welcome
#sed -i "s/org.fedoraproject.AnacondaInstaller/fedora-logo-icon/g" /usr/share/applications/liveinst.desktop

# Show harddisk install on the desktop
sed -i -e 's/NoDisplay=true/NoDisplay=false/' /usr/share/applications/liveinst.desktop
mkdir /home/liveuser/Desktop
cp /usr/share/applications/liveinst.desktop /home/liveuser/Desktop/

if [ -f /usr/share/anaconda/gnome/fedora-welcome.desktop  ]; then
  mkdir -p ~liveuser/.config/autostart
  cp /usr/share/anaconda/gnome/fedora-welcome.desktop /usr/share/applications/
  cp /usr/share/anaconda/gnome/fedora-welcome.desktop ~liveuser/.config/autostart/
fi

# no updater applet in live environment
rm -f /etc/xdg/autostart/org.mageia.dnfdragora-updater.desktop

# and mark it as executable (new Xfce security feature)
chmod +x /home/liveuser/Desktop/liveinst.desktop

# move to anaconda - probably not required for XFCE.
mv /usr/share/applications/liveinst.desktop /usr/share/applications/anaconda.desktop

# this goes at the end after all other changes. 
chown -R liveuser:liveuser /home/liveuser
restorecon -R /home/liveuser
restorecon -R /

EOF

# this doesn't come up automatically. not sure why.
systemctl enable --force lightdm.service

# CRB needs to be enabled for EPEL to function.
dnf config-manager --set-enabled crb

%end
