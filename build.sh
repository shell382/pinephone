#!/bin/bash

set -xe

OUT="$(realpath "$1" 2>/dev/null || echo 'out')"
mkdir -p "$OUT"

TMP=$(mktemp -d)
HERE=$(pwd)
SCRIPT="$(dirname "$(realpath "$0")")"/build

mkdir "${TMP}/system"
mkdir "${TMP}/partitions"

TMPDOWN=$(mktemp -d)
cd "$TMPDOWN"
    wget -O 'uboot.zip' 'https://gitlab.com/pine64-org/crust-meta/-/jobs/artifacts/master/download?job=build'
    wget -O 'linux-image-5.13.1-pine64_5.13.1-pine64-1_arm64.deb' 'https://gitlab.com/ubports/community-ports/non-android/linux/-/jobs/artifacts/pine-a64-5.13.y-megi/raw/linux-image-5.13.1-pine64_5.13.1-pine64-1_arm64.deb?job=build'
    wget -O 'recovery-pinephone.img.xz' 'https://gitlab.com/ubports/core/jumpdrive-ubports/-/jobs/artifacts/ubports-recovery/raw/recovery-pinephone.img.xz?job=build'
    wget -O 'recovery-pinetab.img.xz' 'https://gitlab.com/ubports/core/jumpdrive-ubports/-/jobs/artifacts/ubports-recovery/raw/recovery-pinetab.img.xz?job=build'
    wget -O 'initrd.img-touch-arm64pinephone' 'https://gitlab.com/ubports/core/initramfs-tools-ubuntu-touch/-/jobs/artifacts/xenial_-_edge_-_pine/raw/out/initrd.img-touch-arm64pinephone?job=build'
    wget -O 'initrd.img-touch-arm64pinetab' 'https://gitlab.com/ubports/core/initramfs-tools-ubuntu-touch/-/jobs/artifacts/xenial_-_edge_-_pine/raw/out/initrd.img-touch-arm64pinetab?job=build'
    unzip "$TMPDOWN/uboot.zip"
    unxz 'recovery-pinephone.img.xz'
    unxz 'recovery-pinetab.img.xz'
    ls .
cd "$HERE"

"$SCRIPT/deb-to-bootimg.sh" "${TMPDOWN}/linux-image-*-pine64_*.deb" "${TMPDOWN}/initrd.img-touch-arm64pinephone" "${TMP}/partitions/boot.img"
"$SCRIPT/wget-extract-deb.sh" 'https://repo.ubports.com/pool/xenial/main/l/linux-firmware-rtlwifi/linux-firmware-rtlwifi_20200316+0ubports0+0~xenial20200412191958.2~1.gbpdcaffd_all.deb' "${TMP}/system"
"$SCRIPT/wget-extract-deb.sh" 'https://repo.ubports.com/pool/xenial/main/l/linux-firmware-pine64-rtl8723-bt/linux-firmware-pine64-rtl8723-bt_20200705+0ubports0+0~20210412140941.5+ubports16.04~1.gbp00406b_all.deb' "${TMP}/system"
"$SCRIPT/mk-persist.sh" 'uboot' "${TMP}/partitions/"

cd "${HERE}"
"$SCRIPT/mk-scr.sh" 'pinephone' 'uboot' "${TMP}/partitions/"
cp "${TMPDOWN}/u-boot-sunxi-with-spl-pinephone.bin" "${TMP}/partitions/loader.img"
cp "${TMPDOWN}/recovery-pinephone.img" "${TMP}/partitions/recovery.img"
cp -av overlay/* "${TMP}/"
"$SCRIPT/build-tarball-mainline.sh" pinephone "${OUT}" "${TMP}"

cd "${HERE}"
"$SCRIPT/mk-scr.sh" 'pinetab' 'uboot' "${TMP}/partitions/"
"$SCRIPT/deb-to-bootimg.sh" "${TMPDOWN}/linux-image-*-pine64_*.deb" "${TMPDOWN}/initrd.img-touch-arm64pinetab" "${TMP}/partitions/boot.img"
cp "${TMPDOWN}/u-boot-sunxi-with-spl-pinephone.bin" "${TMP}/partitions/loader.img"
cp "${TMPDOWN}/recovery-pinetab.img" "${TMP}/partitions/recovery.img"
cp -av overlay/* "${TMP}/"
"$SCRIPT/build-tarball-mainline.sh" pinetab "${OUT}" "${TMP}"

rm -r "${TMP}"
rm -r "${TMPDOWN}"

echo "done"
