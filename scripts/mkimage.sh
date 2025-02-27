#!/bin/bash
# shellcheck disable=SC2115
set -ex
shopt -s expand_aliases
alias gzip="gzip -n -9"

usage() {
  echo "Usage: $0 [VARIANT] [DIST]"
  echo
  echo "[VARIANT]: The debian variant to use."
  echo "[DIST]: The debian dist to use."
  echo "[SOURCES]: The debian sources to use."
  echo
  exit 1
}

if [ $# -ne 3 ]; then
    usage
fi

VARIANT=$1
DIST=$2
SOURCES=$3

WORKDIR="/workspace/$DIST"

ROOTFSDIR=$(cd "$(dirname "$0")/../debootstrap/$DIST/rootfs";pwd)
mkdir -p "$WORKDIR"

debootstrap --variant="$VARIANT" "$DIST" "$WORKDIR" "$SOURCES"/debian
if [ -d "$ROOTFSDIR" ];then
  cp -rf "$ROOTFSDIR"/* "$WORKDIR"
fi

rootfs_chroot() {
    PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
        chroot "$WORKDIR" "$@"
}

# Add some tools we need.
rootfs_chroot apt-get install -y --no-install-recommends \
  tini \
  curl \
  netbase \
  pax-utils \
  ca-certificates

# We have our own version of initctl, tell dpkg to not overwrite it.
rootfs_chroot dpkg-divert --local --rename --add /sbin/initctl

# Remove default mirrors
rm -rf "$WORKDIR"/etc/apt/sources.list
# Set the mirrors to distro-based ones
cat << EOF > "$WORKDIR"/etc/apt/sources.list.d/debian.sources
Types: deb
URIs: $SOURCES/debian
Suites: $DIST $DIST-updates
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: $SOURCES/debian-security
Suites: $DIST-security
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# Do a final upgrade.
rootfs_chroot apt-get update
rootfs_chroot apt-get -y -q upgrade

# Clean some apt artifacts
rootfs_chroot apt-get clean

# Delete dirs we don't need, leaving the entries.
rm -rf "$WORKDIR"/var/log
rm -rf "$WORKDIR"/var/cache/apt
rm -rf "$WORKDIR"/var/lib/apt/lists
rm -rf "$WORKDIR"/var/cache/ldconfig/aux-cache
rm -rf "$WORKDIR"/usr/share/locale
rm -rf "$WORKDIR"/usr/share/info
rm -rf "$WORKDIR"/usr/share/man
rm -rf "$WORKDIR"/etc/apt/apt.conf.d/01autoremove-kernels

# Remove /usr/share/doc, but leave copyright files to be sure that we
# comply with all licenses.
# `mindepth 2` as we only want to remove files within the per-package
# directories. Crucially some packages use a symlink to another package
# dir (e.g. libgcc1), and we don't want to remove those.
find "$WORKDIR"/usr/share/doc -mindepth 2 -not -name copyright -not -type d -delete
find "$WORKDIR"/usr/share/doc -mindepth 1 -type d -empty -delete

# Hardcode this somewhere
rm -f "$WORKDIR"/etc/machine-id

# This gets overridden by Container at runtime.
rm -f "$WORKDIR"/etc/hostname

# Create required directory
rootfs_chroot mkdir -p /opt/drycc
rootfs_chroot mkdir -p /var/log/apt

# pass -n to gzip to strip timestamps
# strip the '.' with --transform that tar includes at the root to build a real rootfs
tar --numeric-owner -czf /workspace/"$DIST".tar.gz -C "$WORKDIR" . --transform='s,^./,,' --mtime='1970-01-01'
md5sum /workspace/"$DIST".tar.gz
