#!/bin/bash

IMAGE_NAME=temp-openwrt-builder

SUDO=$(which sudo || echo "")

set -e

mkdir -p ./build
rm -rf ./build/build.iso

[ ! -f ./apt-proxy.txt ] && touch apt-proxy.txt

$SUDO docker build --tag=$IMAGE_NAME .
$SUDO docker run --rm -it -v $PWD/build:/mnt/output $IMAGE_NAME cp /work/build.iso /mnt/build/build.iso

echo "Success!"

