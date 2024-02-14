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

sed -i 's/^livesys_session=.*/livesys_session="xfce"/' /etc/sysconfig/livesys

# this doesn't come up automatically. not sure why.
systemctl enable --force lightdm.service

# CRB needs to be enabled for EPEL to function.
dnf config-manager --set-enabled crb

%end
