# R8 specific kickstarts

This branch has Rocky Linux 8 specific kickstarts. These kickstarts vary
between cloud images and live images provided in our repositories and
mirrors.

## Structure

In the root of the repository are the general kickstarts in use that any
user can pick up, use, or modify to their liking to make their own Rocky
Linux live images, cloud images, and so on. These kickstarts are generated
by templates that live in the various directories in this repository.

* `cloud` -> Cloud image templates
* `live` -> Live image templates
* `container` -> Container image templates

These kickstarts are generated using `ksflatten`. Changes made to the
kickstarts generally match between the templates and the full kickstarts
in the root.

For SIG/Core's usage, we use the `live` area as a "working" directory,
where we use the split parts in our automation for the images and the
pre-flattened versions are there for the convenience of all users. This
is easier than using the pre-made ones in empanadas.

## Building Live Images

To build live images, you will need to use `livecd-creator` or
`livemedia-creator`. The former is simpler to use and generally works without
many issues. The latter can be a bit more tricky to work with and typically
runs the installer virtually. However, it can be used without a virtual machine
like in a mock shell.

### Using livemedia-creator

To use livemedia-creator without using virt, you can use a mock shell. To
setup a mock chroot for the purpose of building a live image, you would
set it up like so:

```
# Install mock if you haven't already
% dnf install epel-release -y
% dnf install mock -y

# Add a user to the mock group
% usermod -a -G mock user

# As the user, setup the mock environment
% mock -r rocky-8-x86_64 --init
% mock -r rocky-8-x86_64 --install lorax-lmc-novirt vim-minimal pykickstart git
# You will need to be in permissive mode temporarily
% setenforce 0
# Enter the shell
% mock -r rocky-8-x86_64 --shell --isolation=simple --enable-network

# Clone the kickstarts and run an installation
% git clone https://github.com/rocky-linux/kickstarts
% cd kickstarts
% livemedia-creator --ks Rocky-8-Workstation.ks \
  --no-virt \
  --resultdir /var/lmc \
  --project="Rocky Linux" \
  --make-iso \
  --volid Rocky-Workstation-8 \
  --iso-only \
  --iso-name Rocky-Workstation-8-x86_64.iso \
  --releasever=8 \
  --nomacboot  # This option is important to set, mkfs.hfsplus is not available
```

With the example above, all of the results will appear in
`/var/lib/mock/rocky-8-x86_64/root/var/lmc`.
