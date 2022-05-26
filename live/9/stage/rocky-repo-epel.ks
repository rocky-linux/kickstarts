# These should change based on the major/minor release

# Deps repo, there are some anaconda packages that are *not* available by default
repo --name=BaseOS --cost=200 --baseurl=http://dl.rockylinux.org/stg/rocky/9.0/BaseOS/$basearch/os/
repo --name=AppStream --cost=200 --baseurl=http://dl.rockylinux.org/stg/rocky/9.0/AppStream/$basearch/os/
repo --name=CRB --cost=200 --baseurl=http://dl.rockylinux.org/stg/rocky/9.0/CRB/$basearch/os/
repo --name=extras --cost=200 --baseurl=http://dl.rockylinux.org/stg/rocky/9.0/extras/$basearch/os

# EPEL (required for KDE and XFCE)
repo --name=epel --cost=200 --baseurl=https://dl.fedoraproject.org/pub/epel/8/Everything/$basearch/
repo --name=epel-modular --cost=200 --baseurl=https://dl.fedoraproject.org/pub/epel/8/Modular/$basearch/

# URL to the base os repo
url --url=http://dl.rockylinux.org/stg/rocky/9.0/BaseOS/$basearch/os/
#url --url=http://10.100.0.1/pub/deps
