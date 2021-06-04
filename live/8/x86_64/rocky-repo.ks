# These should change based on the major/minor release

# Deps repo, there are some anaconda packages that are *not* available by default
repo --name=LiveDeps --baseurl=http://dl.rockylinux.org/pub/rocky/8.3/LiveDeps/x86_64/os/

# Base repos
repo --name=BaseOS --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/BaseOS/x86_64/os/
repo --name=AppStream --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/AppStream/x86_64/os/
repo --name=PowerTools --baseurl=http://dl.rockylinux.org/pub/rocky/8.4/PowerTools/x86_64/os/

# URL to the base os repo
url --url=http://dl.rockylinux.org/pub/rocky/8.4/BaseOS/x86_64/os/
