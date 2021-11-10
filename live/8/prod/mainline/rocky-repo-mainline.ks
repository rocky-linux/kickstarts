# These should change based on the major/minor release

# Deps repo, there are some anaconda packages that are *not* available by default
repo --name=BaseOS --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.5/BaseOS/$basearch/os/
repo --name=AppStream --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.5/AppStream/$basearch/os/
repo --name=PowerTools --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.5/PowerTools/$basearch/os/
repo --name=extras --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.5/extras/$basearch/os

# ELRepo
repo --name="elrepo-kernel" --baseurl=https://elrepo.org/linux/kernel/el8/$basearch/ --cost=200

# URL to the base os repo
url --url=http://dl.rockylinux.org/pub/rocky/8.5/BaseOS/$basearch/os/
#url --url=http://10.100.0.1/pub/deps
