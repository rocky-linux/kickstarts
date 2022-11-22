text
lang en_US.UTF-8
keyboard us
timezone UTC --isUtc
# Disk
auth --enableshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=ssh
firstboot --disable
# Network information
network  --bootproto=dhcp --device=link --activate --onboot=on
network  --hostname=localhost.localdomain
# Root password
services --disabled="kdump" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd"
rootpw --iscrypted thereisnopasswordanditslocked
url --url https://download.rockylinux.org/stg/rocky/8/BaseOS/$basearch/os/
shutdown
