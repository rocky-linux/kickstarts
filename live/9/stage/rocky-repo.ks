# These should change based on the major/minor release

# Base repos
repo --name=BaseOS --cost=200 --baseurl=http://dl.rockylinux.org/stg/rocky/9/BaseOS/$basearch/os/
repo --name=AppStream --cost=200 --baseurl=http://dl.rockylinux.org/stg/rocky/9/AppStream/$basearch/os/
repo --name=CRB --cost=200 --baseurl=http://dl.rockylinux.org/stg/rocky/9/CRB/$basearch/os/
repo --name=extras --cost=200 --baseurl=http://dl.rockylinux.org/stg/rocky/9/extras/$basearch/os

# URL to the base os repo
url --url=http://dl.rockylinux.org/stg/rocky/9/BaseOS/$basearch/os/
