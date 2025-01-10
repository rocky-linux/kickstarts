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

# set default background
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<XFCEEOF
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="color-style" type="int" value="0"/>
        <property name="image-style" type="int" value="5"/>
        <property name="last-image" type="string" value="/usr/share/backgrounds/rocky-default-9-abstract-2-day.png"/>
        <property name="last-single-image" type="string" value="/usr/share/backgrounds/rocky-default-9-abstract-2-day.png"/>
        <property name="image-path" type="string" value="/usr/share/backgrounds/rocky-default-9-abstract-2-day.png"/>
      </property>
    </property>
  </property>
</channel>
XFCEEOF

sed -i 's/^livesys_session=.*/livesys_session="xfce"/' /etc/sysconfig/livesys

# this doesn't come up automatically. not sure why.
systemctl enable --force lightdm.service

# CRB needs to be enabled for EPEL to function.
dnf config-manager --set-enabled crb

%end
