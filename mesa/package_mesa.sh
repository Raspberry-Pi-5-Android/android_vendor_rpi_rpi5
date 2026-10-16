#!/usr/bin/env bash
# Copy a Mesa build produced by build_mesa.sh into this directory.
#
# Usage:
#   MESA_SRC=/path/to/mesa OUT=/path/to/out ./package_mesa.sh
#
# The libraries are checked against the sha256 sums in $OUT/BUILD_INFO before
# they are copied. The Vulkan driver is renamed to vulkan.broadcom.so (the HAL
# module loaded for ro.hardware.vulkan=broadcom) and its SONAME is set to
# match. License texts are copied from the Mesa tree and its subprojects.
set -euo pipefail

: "${MESA_SRC:?set MESA_SRC to the Mesa source tree}"
: "${OUT:?set OUT to the build_mesa.sh output directory}"

HERE=$(cd "$(dirname "$0")" && pwd)
LIB="$OUT/install/vendor/lib64"

(cd "$LIB" && grep -E '^[0-9a-f]{64}  [^ ]+\.so$' "$OUT/BUILD_INFO" | sha256sum --check --strict -)

rm -rf "$HERE/prebuilt" "$HERE/licenses"
mkdir -p "$HERE/prebuilt/arm64/egl" "$HERE/prebuilt/arm64/hw" "$HERE/licenses"

for lib in libEGL_mesa libGLESv1_CM_mesa libGLESv2_mesa libgallium_dri; do
    install -m 0644 "$LIB/$lib.so" "$HERE/prebuilt/arm64/egl/$lib.so"
done
install -m 0644 "$LIB/libvulkan_broadcom.so" "$HERE/prebuilt/arm64/hw/vulkan.broadcom.so"
patchelf --set-soname vulkan.broadcom.so "$HERE/prebuilt/arm64/hw/vulkan.broadcom.so"

install -m 0644 "$MESA_SRC/docs/license.rst" "$HERE/licenses/MESA_LICENSE.rst"
install -m 0644 "$MESA_SRC/subprojects/expat-2.5.0/COPYING" "$HERE/licenses/EXPAT_COPYING"
# libdrm has no single license file; its MIT notice is in the source headers.
{
    echo "libdrm 2.4.133 (linked statically). Notice from xf86drm.c:"
    echo
    sed -n '10,31p' "$MESA_SRC/subprojects/libdrm-2.4.133/xf86drm.c" | sed -E 's/^ \* ?//'
} > "$HERE/licenses/LIBDRM_NOTICE"
grep -q 'Permission is hereby granted' "$HERE/licenses/LIBDRM_NOTICE" \
    || { echo "libdrm notice not found" >&2; exit 1; }

{
    cat "$OUT/BUILD_INFO"
    echo "patchelf=$(patchelf --version)"
} > "$HERE/BUILD_INFO"
(cd "$HERE" && find prebuilt -type f | LC_ALL=C sort | xargs sha256sum) > "$HERE/SHA256SUMS"
echo "Packaged into $HERE"
