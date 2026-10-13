#!/usr/bin/env bash
# Makes the bundle's FFmpeg self-contained. Run by the install step in
# CMakeLists.txt with the bundle's lib/ directory as its argument.
#
# On Windows the plugin's FFmpeg is complete in itself. On Linux it is not:
# libavcodec and its siblings are linked against the codec libraries of the
# distribution they were built on (libvpx.so.7, libx265.so.199, libxvidcore,
# libass...), under the exact sonames that distribution uses. A user would
# have to install those, and on a newer distribution they do not exist under
# those names at all. That is "configure FFmpeg yourself" by another route,
# which this app does not ask of anyone.
#
# So the libraries FFmpeg pulls in are copied next to it, except the ones any
# desktop already has with a stable ABI: glibc, the C++ runtime, X11 and the
# GTK stack the app itself needs. The plugin's own direct dependencies are
# treated the same way. Then every FFmpeg library, every copy, and
# the plugin get RUNPATH=$ORIGIN. RUNPATH applies only to an object's own
# dependencies, never to what it dlopens or to its dependencies' dependencies,
# so each one has to carry it. The plugin is included because it dlopens
# libffmpegkit.so, and it was linked with a RUNPATH pointing into the build
# directory.
set -euo pipefail

lib_dir=$1
cd "$lib_dir"

if ! command -v patchelf >/dev/null; then
  echo "bundle-ffmpeg-libraries: patchelf is required (apt install patchelf)" >&2
  exit 1
fi

# Present on every desktop that can show a GTK window, with sonames that have
# held for years. Anything else travels with the app. libgomp is deliberately
# not here: vidstab needs it, and a clean Ubuntu 24.04 does not have it.
baseline='^(ld-linux.*|libc|libm|libdl|libpthread|librt|libresolv|libutil|libstdc\+\+|libgcc_s|libgtk-3|libgdk-3|libgdk_pixbuf-2\.0|libpango.*|libatk.*|libz|liblzma|libbz2|libexpat|libffi|libuuid|libbsd|libmd|libX[a-zA-Z0-9]*|libxcb.*|libGL.*|libEGL.*|libdrm|libfontconfig|libfreetype|libpng16|libbrotli.*|libharfbuzz|libfribidi|libgraphite2|libpixman-1|libcairo.*|libglib-2\.0|libgobject-2\.0|libgio-2\.0|libgmodule-2\.0|libpcre2?.*|libgnutls|libnettle|libhogweed|libgmp|libtasn1|libidn2|libunistring|libp11-kit|libasound|libpulse.*|libsystemd|libdbus-1|libselinux|libmount|libblkid|libcap)\.so'

ffmpeg_libraries=(libffmpegkit.so.* libav*.so.* libsw*.so.* libpostproc.so.*)

copied=()
missing=()
while read -r name arrow path _; do
  [[ "$arrow" == "=>" ]] || continue
  if [[ "$path" == "not" ]]; then
    missing+=("$name")
    continue
  fi
  [[ "$name" =~ $baseline ]] && continue
  [[ -e "$name" ]] && continue
  cp -L "$path" "$name"
  copied+=("$name")
done < <({
  for library in "${ffmpeg_libraries[@]}"; do
    [[ -f "$library" && ! -L "$library" ]] || continue
    LD_LIBRARY_PATH=. ldd "$library"
  done
  # The plugin's own direct dependencies too, for json-glib: GNOME has it,
  # other desktops need not. Only the direct ones, because everything behind
  # them is GTK's, and GTK is the system's.
  plugin=libffmpeg_kit_flutter_new_plugin.so
  direct=$(readelf -d "$plugin" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p')
  LD_LIBRARY_PATH=. ldd "$plugin" | grep -F -w -f <(printf '%s\n' "$direct")
} | sort -u)

if (( ${#missing[@]} )); then
  echo "bundle-ffmpeg-libraries: FFmpeg needs libraries this machine lacks:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 1
fi

for library in "${ffmpeg_libraries[@]}" "${copied[@]}" \
    libffmpeg_kit_flutter_new_plugin.so; do
  [[ -f "$library" && ! -L "$library" ]] || continue
  patchelf --set-rpath '$ORIGIN' "$library"
done

echo "bundle-ffmpeg-libraries: copied ${#copied[@]} libraries FFmpeg depends on"
