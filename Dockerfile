FROM ubuntu:20.04
MAINTAINER Joseph Lee <development@jc-lab.net>

ARG DEBIAN_FRONTEND=noninteractive

COPY ["apt-mirror.txt", "/tmp/apt-mirror.txt"]
RUN APT_REPO=$(cat /tmp/apt-mirror.txt | head -n 1) && \
    echo "APT_REPO: $APT_REPO" && \
    echo "\n\
deb $APT_REPO focal main restricted universe multiverse\n\
deb $APT_REPO focal-updates main restricted universe multiverse\n\
deb $APT_REPO focal-backports main restricted universe multiverse\n\
deb $APT_REPO focal-security main restricted universe multiverse\n\
" > /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get install -y debootstrap \
    squashfs-tools dosfstools \
    xorriso \
    isolinux \
    syslinux-efi \
    grub-pc-bin \
    grub-efi-amd64-bin grub-efi-amd64-signed \
    shim-signed \
    mtools

ENV WORK_DIR=/work
RUN mkdir -p $WORK_DIR

RUN debootstrap \
    --arch=amd64 \
    --variant=minbase \
    focal \
    $WORK_DIR/chroot \
    http://mirror.kakao.com/ubuntu/

RUN mkdir -p \
    $WORK_DIR/staging \
    $WORK_DIR/staging/efi/boot \
    $WORK_DIR/staging/boot/grub/x86_64-efi \
    $WORK_DIR/staging/isolinux \
    $WORK_DIR/staging/live \
    $WORK_DIR/staging/.disk \
    $WORK_DIR/staging/target \
    $WORK_DIR/tmp \
    $WORK_DIR/chroot/tmp && \
    cp /etc/apt/sources.list $WORK_DIR/chroot/etc/apt/sources.list

COPY ["chroot/stage-1.sh", "$WORK_DIR/chroot/tmp/stage-1.sh"]
RUN chmod +x $WORK_DIR/chroot/tmp/stage-1.sh && \
    chroot $WORK_DIR/chroot/ /tmp/stage-1.sh

COPY ["chroot/stage-2.sh", "$WORK_DIR/chroot/tmp/stage-2.sh"]
RUN chmod +x $WORK_DIR/chroot/tmp/stage-2.sh && \
    chroot $WORK_DIR/chroot/ /tmp/stage-2.sh

COPY ["chroot/stage-cleanup.sh", "$WORK_DIR/chroot/tmp/stage-cleanup.sh"]
RUN chmod +x $WORK_DIR/chroot/tmp/stage-cleanup.sh && \
    chroot $WORK_DIR/chroot/ /tmp/stage-cleanup.sh

ARG OPENWRT_VERSION=
COPY ["build/openwrt.img.gz", "$WORK_DIR/chroot/openwrt.img.gz"]
COPY ["installer", "$WORK_DIR/chroot/opt/installer"]
RUN chmod +x $WORK_DIR/chroot/opt/installer/*.sh && \
    echo "$OPENWRT_VERSION" > /openwrt-version.txt

ARG BOOT_FIND_ID=openwrt_install

RUN rm -rf $WORK_DIR/chroot/tmp/* && \
    mksquashfs \
    $WORK_DIR/chroot \
    $WORK_DIR/staging/live/filesystem.squashfs \
    -e boot \
    -Xcompression-level 5

RUN cp $WORK_DIR/chroot/boot/vmlinuz-* \
    $WORK_DIR/staging/live/vmlinuz && \
    cp $WORK_DIR/chroot/boot/initrd.img-* \
    $WORK_DIR/staging/live/initrd

COPY ["static-boot", "/tmp/static-boot"]
RUN cp /tmp/static-boot/isolinux.cfg $WORK_DIR/staging/isolinux/isolinux.cfg && \
    cp /tmp/static-boot/grub.cfg $WORK_DIR/staging/boot/grub/grub.cfg && \
    cp /tmp/static-boot/grub-standalone.cfg $WORK_DIR/tmp/grub.cfg && \
    sed -i -e 's,<BOOT_FIND_ID>,'$BOOT_FIND_ID',g' $WORK_DIR/staging/boot/grub/grub.cfg && \
    sed -i -e 's,<BOOT_FIND_ID>,'$BOOT_FIND_ID',g' $WORK_DIR/tmp/grub.cfg && \
    touch $WORK_DIR/staging/.disk/$BOOT_FIND_ID && \
    cp /usr/lib/ISOLINUX/isolinux.bin $WORK_DIR/staging/isolinux/ && \
    cp /usr/lib/syslinux/modules/bios/* $WORK_DIR/staging/isolinux/ && \
    cp /usr/lib/shim/shimx64.efi.signed $WORK_DIR/tmp/bootx64.efi && \
    cp /usr/lib/shim/mmx64.efi $WORK_DIR/tmp/mmx64.efi && \
    cp /usr/lib/shim/fbx64.efi $WORK_DIR/tmp/mmx64.efi && \
    cp /usr/lib/grub/x86_64-efi-signed/gcdx64.efi.signed $WORK_DIR/tmp/grubx64.efi && \
    cp $WORK_DIR/tmp/* $WORK_DIR/staging/efi/boot/ && \
    (cd $WORK_DIR/staging/boot/ && \
      dd if=/dev/zero of=efiboot.img bs=1M count=16 && \
      mkfs.vfat efiboot.img && \
      mmd -i efiboot.img efi efi/boot && \
      mcopy -vi efiboot.img \
                $WORK_DIR/tmp/* \
                ::efi/boot/ \
    )

RUN xorriso \
    -as mkisofs \
    -iso-level 3 \
    -o "$WORK_DIR/output.iso" \
    -full-iso9660-filenames \
    -volid "openwrt_iso" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-boot \
        isolinux/isolinux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog isolinux/isolinux.cat \
    -eltorito-alt-boot \
        -e /boot/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
    -append_partition 2 0xef $WORK_DIR/staging/boot/efiboot.img \
    "$WORK_DIR/staging"

