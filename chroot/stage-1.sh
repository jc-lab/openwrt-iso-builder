#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y \
    live-boot bash-completion vim sudo gdisk fdisk hdparm unzip \
    linux-image-generic grub-pc-bin grub-efi grub-efi-amd64 grub-efi-amd64-signed shim-signed efibootmgr \
    curl wget tar squashfs-tools openssl dosfstools \
    openssh-server openssh-sftp-server openssh-client \
    network-manager net-tools isc-dhcp-client netplan.io wireless-tools \
    cloud-init bsdmainutils

systemctl enable cloud-init-local.service
systemctl enable cloud-init.service
systemctl enable cloud-init.service
systemctl enable systemd-networkd.service
systemctl disable systemd-networkd-wait-online.service

