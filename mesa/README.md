# Mesa for Raspberry Pi 5

Prebuilt Mesa drivers for the VideoCore VII GPU of the BCM2712, built from
unmodified upstream Mesa with the Android NDK.

| File | Installed as | Purpose |
|---|---|---|
| `prebuilt/arm64/egl/libEGL_mesa.so` | `/vendor/lib64/egl/` | EGL (`ro.hardware.egl=mesa`) |
| `prebuilt/arm64/egl/libGLESv1_CM_mesa.so` | `/vendor/lib64/egl/` | OpenGL ES 1.x |
| `prebuilt/arm64/egl/libGLESv2_mesa.so` | `/vendor/lib64/egl/` | OpenGL ES 2.0-3.x |
| `prebuilt/arm64/egl/libgallium_dri.so` | `/vendor/lib64/egl/` | Gallium drivers `v3d` and `vc4` |
| `prebuilt/arm64/hw/vulkan.broadcom.so` | `/vendor/lib64/hw/` | Vulkan driver `v3dv` (`ro.hardware.vulkan=broadcom`) |

Only 64-bit libraries are provided.

## Provenance

- `BUILD_INFO`: Mesa tag and commit, NDK revision, toolchain versions, the
  subprojects with their source hashes, and the sha256 of each library as
  built.
- `SHA256SUMS`: sha256 of the files in `prebuilt/`. The Vulkan driver differs
  from the built `libvulkan_broadcom.so` only in its file name and SONAME,
  which `package_mesa.sh` sets with patchelf.

Two clean builds with the pinned inputs produce identical libraries.

## Rebuilding

1. Mesa: `git clone --branch mesa-26.2.5 https://gitlab.freedesktop.org/mesa/mesa.git`
2. Android NDK r30 (`30.0.16248370`): https://developer.android.com/ndk/downloads
3. Host tools: meson >= 1.4, ninja, bison, flex, Python 3 with mako, PyYAML and
   packaging, glslang, patchelf.
4. Build: `NDK=<ndk> MESA_SRC=<mesa> OUT=<out> ./build_mesa.sh`
5. Package: `MESA_SRC=<mesa> OUT=<out> ./package_mesa.sh`
6. Check: `sha256sum -c SHA256SUMS`

## Licenses

See `licenses/`: Mesa (`MESA_LICENSE.rst`, mostly MIT; the file lists the
exceptions), libdrm (`LIBDRM_NOTICE`, MIT) and expat (`EXPAT_COPYING`, MIT).
libdrm and expat are linked statically.
