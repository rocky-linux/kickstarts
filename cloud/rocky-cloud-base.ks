text
lang en_US.UTF-8
keyboard us
timezone --utc UTC
# Disk
auth --enableshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=ssh
firstboot --disable
# Network information
network  --bootproto=dhcp --device=link --activate --onboot=on
# Root password
services --disabled="kdump,rhsmcertd" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd"
rootpw --iscrypted thereisnopasswordanditslocked
url --url https://download.rockylinux.org/stg/rocky/10/BaseOS/$basearch/os/
shutdown
