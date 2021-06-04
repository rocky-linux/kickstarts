# These should change based on the major/minor release

# Deps repo, there are some anaconda packages that are *not* available by default
repo --name=livedeps --includepkgs=anaconda-live --cost=500 --baseurl=https://kojidev.rockylinux.org/kojifiles/repos/dist-rocky8_4-updates-build/latest/x86_64/

# Base repos
repo --name=BaseOS --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/BaseOS/x86_64/os/
repo --name=AppStream --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/AppStream/x86_64/os/
repo --name=PowerTools --cost=200 --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/PowerTools/x86_64/os/

# URL to the base os repo
url --url=http://dl.rockylinux.org/pub/rocky/8.4/BaseOS/x86_64/os/
