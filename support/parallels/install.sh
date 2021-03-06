#!/bin/bash

set -o errexit -o pipefail

cd /

### Dependencies installation ###

# Install dkms
pacman -S --noconfirm dkms

# Install multipath-tools because Parallels Tools requires kpartx
curl -o /tmp/multipath-tools.tar.gz \
  https://aur.archlinux.org/cgit/aur.git/snapshot/multipath-tools.tar.gz
# Extract...
tar -xf /tmp/multipath-tools.tar.gz -C /tmp
chmod -R 777 /tmp/multipath-tools
cd /tmp/multipath-tools
# Build and install! We must do this as non-root, otherwise makepkg will blow up
su vagrant -c 'makepkg --syncdeps --clean --noconfirm --install'
cd /

### Parallels Tools installation ###

# Mount the iso
mkdir -p /mnt/iso
mount /tmp/prl-tools-lin.iso /mnt/iso

# Move the iso's contents to a writable location
cp -r /mnt/iso /tmp/prltools

# Staging area for Parallels Tools patching - currently no patches needed.

# Persuade the installer that we are running a compatible Linux flavour
ln -sf /usr/lib/systemd/scripts /etc/init.d
export def_sysconfdir=/etc/init.d

# Install!
/tmp/prltools/install --install-unattended

# Configure systemd unit
mv /tmp/parallels/parallels-tools.service /usr/lib/systemd/system/
chown root:root /usr/lib/systemd/system/parallels-tools.service
systemctl enable parallels-tools.service

# Cleanup
umount /mnt/iso
rm -rf /mnt/iso
rm -rf /etc/init.d
rm -rf /var/log/parallels.log # It contains my shared folders! I don't want you guys to see that!:)


### Fixes for known errors ###

cat <<LIST >> /etc/modprobe.d/blacklist.conf
# Disable intel_rapl to stop errors about no valid rapl domains
blacklist intel_rapl
LIST

# Regenerate ramdisk
mkinitcpio -p linux
