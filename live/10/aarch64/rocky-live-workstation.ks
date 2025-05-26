# Maintained by Release Engineering
# mailto:releng@rockylinux.org

%include rocky-live-base.ks
%include rocky-workstation-common.ks
#
# Disable this for now as packagekit is causing compose failures
# by leaving a gpg-agent around holding /dev/null open.
#
#include snippets/packagekit-cached-metadata.ks

part / --size 8192

%packages
gnome-initial-setup
%end

%post

sed -i 's/^livesys_session=.*/livesys_session="gnome"/' /etc/sysconfig/livesys

%end
