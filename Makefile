TEMP_DOCKER_IMAGE=temp-openwrt_iso_builder

USE_EFI = true
OPENWRT_VERSION=21.02.3
OPENWRT_URL=https://downloads.openwrt.org/releases/$(OPENWRT_VERSION)/targets/x86/64/generic-squashfs-combined$(if $(filter ${USE_EFI},true),-efi,).img.gz

PWD := $(shell pwd)
UID := $(shell id -u)
GID := $(shell id -g)

.DEFAULT_GOAL := build/output.iso

build/output.iso: build/openwrt.img.gz
	docker build --build-arg OPENWRT_VERSION=${OPENWRT_VERSION} --tag=${TEMP_DOCKER_IMAGE} .
	docker run --rm -v ${PWD}/build:/mnt/output ${TEMP_DOCKER_IMAGE} cp /work/output.iso /mnt/output/output.iso

build/openwrt.img.gz:
	mkdir -p ${PWD}/build/
	wget -O build/openwrt.img.gz ${OPENWRT_URL}

all: build/output.iso

