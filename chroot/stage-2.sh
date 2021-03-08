#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive
NODEJS_VERSION=v12.18.3

mkdir -p /var/lib/cloud/seed/nocloud-net/

cat > /var/lib/cloud/seed/nocloud-net/meta-data <<EOF
local-hostname: ubuntu-live
EOF

cat > /var/lib/cloud/seed/nocloud-net/user-data <<EOF
#cloud-config
growpart:
  mode: 'off'
locale: en_US.UTF-8
preserve_hostname: true
manage_etc_hosts: true
resize_rootfs: false
ssh_pwauth: true
users:
- gecos: live
  groups:
  - adm
  - cdrom
  - dip
  - plugdev
  - lxd
  - sudo
  lock-passwd: false
  name: live
  passwd: '\$6\$mot7L1ldr8jtvGiE\$o3dLgqTqSvqXRY6V.voQ8EuC/g24GgMnlEZaEGqlaLn9jN9FsN7Hh8f/RcJdDLOIZHlreQHadHKNuzs2w0/NK0'
  shell: /bin/bash
  sudo: 'ALL=(ALL) NOPASSWD: ALL'
EOF

# PASSWORD is `live`

sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config

if [ -e /etc/default/locale ]; then
	sed -i -e 's/^LANG=.*$/LANG=en_US.UTF-8/g' /etc/default/locale
else
	echo "LANG=en_US.UTF-8" > /etc/default/locale
fi


