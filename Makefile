TEMP_DOCKER_IMAGE=temp-openwrt_iso_builder

OPENWRT_VERSION=19.07.7
OPENWRT_URL=https://downloads.openwrt.org/releases/$(OPENWRT_VERSION)/targets/x86/64/openwrt-$(OPENWRT_VERSION)-x86-64-combined-squashfs.img.gz

PWD := $(shell pwd)
SUDO := sudo
UID := $(shell id -u)
GID := $(shell id -g)

.DEFAULT_GOAL := build/output.iso

build/output.iso: build/openwrt.img.gz
	${SUDO} docker build --build-arg OPENWRT_VERSION=${OPENWRT_VERSION} --tag=${TEMP_DOCKER_IMAGE} .
	docker run --rm -it -v ${PWD}/build:/mnt/output ${TEMP_DOCKER_IMAGE} cp /work/output.iso /mnt/output/output.iso

build/openwrt.img.gz:
	mkdir -p ${PWD}/build/
	wget -O build/openwrt.img.gz ${OPENWRT_URL}

all: build/output.iso

