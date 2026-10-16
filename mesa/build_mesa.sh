#!/usr/bin/env bash
# Build Mesa (V3D GLES + V3DV Vulkan) for Raspberry Pi 5 with the Android NDK.
#
# Usage:
#   NDK=/path/to/android-ndk-r30 MESA_SRC=/path/to/mesa OUT=/path/to/out ./build_mesa.sh
#
# The script refuses to build unless the NDK revision and the Mesa tag match
# the pinned versions below and the Mesa tree has no local changes.
set -euo pipefail

MESA_TAG=mesa-26.2.5
NDK_REVISION=30.0.16248370
API_LEVEL=35

: "${NDK:?set NDK to the Android NDK directory}"
: "${MESA_SRC:?set MESA_SRC to the Mesa source tree}"
: "${OUT:?set OUT to the output directory}"

ndk_rev=$(sed -n 's/^Pkg.Revision = //p' "$NDK/source.properties")
[ "$ndk_rev" = "$NDK_REVISION" ] || { echo "NDK revision $ndk_rev, expected $NDK_REVISION" >&2; exit 1; }
mesa_tag=$(git -C "$MESA_SRC" describe --tags --exact-match)
[ "$mesa_tag" = "$MESA_TAG" ] || { echo "Mesa tag $mesa_tag, expected $MESA_TAG" >&2; exit 1; }
[ -z "$(git -C "$MESA_SRC" status --porcelain)" ] || { echo "Mesa tree has local changes" >&2; exit 1; }

TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
mkdir -p "$OUT"
CROSS="$OUT/android-aarch64.cross"
cat > "$CROSS" <<EOF
[binaries]
ar = '$TOOLCHAIN/llvm-ar'
c = ['$TOOLCHAIN/aarch64-linux-android$API_LEVEL-clang']
cpp = ['$TOOLCHAIN/aarch64-linux-android$API_LEVEL-clang++', '-fno-exceptions', '-fno-unwind-tables', '-fno-asynchronous-unwind-tables', '-static-libstdc++']
c_ld = 'lld'
cpp_ld = 'lld'
strip = '$TOOLCHAIN/llvm-strip'
# Do not let host pkg-config files leak into the cross build.
pkg-config = ['env', 'PKG_CONFIG_LIBDIR=/nonexistent', '/usr/bin/pkg-config']

[host_machine]
system = 'android'
cpu_family = 'aarch64'
cpu = 'armv8'
endian = 'little'
EOF

# Always start from a clean build and install tree.
rm -rf "$OUT/build" "$OUT/install"
meson setup "$OUT/build" "$MESA_SRC" \
    --cross-file "$CROSS" \
    --buildtype=release \
    --prefix=/vendor \
    --libdir=lib64 \
    -Dplatforms=android \
    -Dplatform-sdk-version=$API_LEVEL \
    -Dandroid-stub=true \
    -Dandroid-libbacktrace=disabled \
    -Dallow-fallback-for=libdrm \
    -Dlibdrm:default_library=static \
    -Dexpat:default_library=static \
    -Dgallium-drivers=v3d,vc4 \
    -Dvulkan-drivers=broadcom \
    -Degl=enabled \
    -Dgles1=enabled \
    -Dgles2=enabled \
    -Dglx=disabled \
    -Dgbm=disabled \
    -Dllvm=disabled \
    -Dxmlconfig=disabled \
    -Dvalgrind=disabled \
    -Dlibunwind=disabled \
    -Dzstd=disabled \
    -Dvideo-codecs= \
    -Degl-lib-suffix=_mesa \
    -Dgles-lib-suffix=_mesa

meson compile -C "$OUT/build"
DESTDIR="$OUT/install" meson install -C "$OUT/build" --strip

{
    echo "mesa_tag=$MESA_TAG"
    echo "mesa_commit=$(git -C "$MESA_SRC" rev-parse HEAD)"
    echo "ndk_revision=$NDK_REVISION"
    echo "api_level=$API_LEVEL"
    echo "clang=$("$TOOLCHAIN/clang" --version | head -1)"
    echo "meson=$(meson --version)"
    echo "ninja=$(ninja --version)"
    for w in "$MESA_SRC"/subprojects/expat.wrap "$MESA_SRC"/subprojects/libdrm.wrap; do
        echo "subproject=$(basename "$w" .wrap) $(sed -n 's/^directory = //p' "$w") source_hash=$(sed -n 's/^source_hash = //p' "$w")"
    done
    (cd "$OUT/install/vendor/lib64" && sha256sum *.so)
} > "$OUT/BUILD_INFO"
echo "Done: $OUT/install"
