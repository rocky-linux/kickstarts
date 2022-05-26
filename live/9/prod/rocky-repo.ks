# These should change based on the major/minor release

# Base repos
repo --name=BaseOS --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/9.0/BaseOS/$basearch/os/
repo --name=AppStream --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/9.0/AppStream/$basearch/os/
repo --name=CRB --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/9.0/CRB/$basearch/os/
repo --name=extras --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/9.0/extras/$basearch/os

# URL to the base os repo
url --url=http://dl.rockylinux.org/pub/rocky/9.0/BaseOS/$basearch/os/
