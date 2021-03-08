#!/bin/bash

DEST_DEVICE=$1

if [ -z $DEST_DEVICE ]; then
	echo "Usage: $0 DEST_DEVICE"
	exit 1
fi

read -p "Are you sure? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	exit 1
fi

gzip -dc /openwrt.img.gz | dd of=$DEST_DEVICE status=progress
sync

echo DONE


