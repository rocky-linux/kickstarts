# Cloud Templates

This directory contains templated versions of the cloud images. This is
extremely useful for us to be able to create more variants or modify
all variants at once if need be.

The general guidelines/ideas work like this:

* Start with a basic name, such as `rocky-${provider}-${variant}.ks`
* Optionally create additional kickstarts, such as an additional packages file
* Include the very base as necessary:

    * rocky-cloud-base.ks
    * rocky-cloud-parts-base.ks or rocky-cloud-parts-lvm.ks

* Include other customizations from another kickstart as necessary, such as an additional packages kickstart
* bootloader configuration and then final %post ... %end section

The most basic example of our most basic generic cloud image goes like this. See comments for details.

```
# rocky-genclo-base.ks

# Imports the absolute base for the cloud images. This is general setup settings.
%include rocky-cloud-base.ks

# Imports partition scheme and creation for the image. This is non-LVM.
%include rocky-cloud-parts-base.ks

# Imports base packages that all cloud images are expected to have
%include rocky-cloud-base-packages.ks

# bootloader information, each cloud will have different settings, so better we put it here.
bootloader --append="console=ttyS0,115200n8 no_timer_check crashkernel=auto net.ifnames=0" --location=mbr --timeout=1

# Anything else can go here that isn't fulfilled by custom or base templates.
# This can be repos if needed.

# the final post section is done here (we've removed all of it for the sake of the example)
%post --erroronfail
. . .
%end
```

At the end, you would run run ksflatten, and you now have a customized kickstart.

```
ksflatten -c rocky-genclo-base.ks -o Rocky-X-GenericCloud-Base.ks
```
