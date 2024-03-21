# These should change based on the major/minor release

# Deps repo, there are some anaconda packages that are *not* available by default
repo --name=BaseOS --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/10/BaseOS/$basearch/os/
repo --name=AppStream --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/10/AppStream/$basearch/os/
repo --name=CRB --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/10/CRB/$basearch/os/
repo --name=extras --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/10/extras/$basearch/os

# EPEL (required for KDE and XFCE)
repo --name=epel --cost=200 --baseurl=https://dl.fedoraproject.org/pub/epel/10/Everything/$basearch/
#repo --name=epel-modular --cost=200 --baseurl=https://dl.fedoraproject.org/pub/epel/10/Modular/$basearch/

# URL to the base os repo
url --url=http://dl.rockylinux.org/pub/rocky/10/BaseOS/$basearch/os/
