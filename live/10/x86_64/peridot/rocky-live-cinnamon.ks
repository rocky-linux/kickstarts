# rocky-live-cinnamon.ks

%include rocky-live-base-spin.ks
%include rocky-live-cinnamon-common.ks

part / --size 8192

%post
# cinnamon configuration

cat > /etc/sysconfig/desktop <<EOF
PREFERRED=/usr/bin/cinnamon-session
DISPLAYMANAGER=/usr/sbin/lightdm
EOF

sed -i 's/^livesys_session=.*/livesys_session="cinnamon"/' /etc/sysconfig/livesys

# this doesn't come up automatically. not sure why.
systemctl enable --force lightdm.service

# CRB needs to be enabled for EPEL to function.
dnf config-manager --set-enabled crb

%end
