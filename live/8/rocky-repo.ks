# These should change based on the major/minor release

# Base repos
repo --name=BaseOS --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/BaseOS/$basearch/os/
repo --name=AppStream --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/AppStream/$basearch/os/
repo --name=PowerTools --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/PowerTools/$basearch/os/
repo --name=extras --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/extras/$basearch/os

# URL to the base os repo
url --url=http://dl.rockylinux.org/pub/rocky/8.4/BaseOS/$basearch/os/
