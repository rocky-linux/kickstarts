# These should change based on the major/minor release

# Base repos
repo --name=BaseOS --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.5/BaseOS/$basearch/os/
repo --name=AppStream --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.5/AppStream/$basearch/os/
repo --name=PowerTools --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.5/PowerTools/$basearch/os/
repo --name=extras --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.5/extras/$basearch/os

# URL to the base os repo
url --url=http://dl.rockylinux.org/pub/rocky/8.5/BaseOS/$basearch/os/
