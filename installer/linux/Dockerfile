# The Linux toolchain for Silence SpeedUp, so that the Linux build can be made
# and tried from Windows. Driven by installer/build-linux.ps1; see
# docs/linux.md.
#
# Ubuntu 22.04 rather than the newest: a Linux binary needs a glibc at least as
# new as the one it was linked against, so building on an older base is what
# lets the bundle run on more distributions.
FROM ubuntu:22.04

ARG FLUTTER_VERSION=3.47.2
ARG USER_ID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

# The first group is Flutter's own Linux prerequisites; libjson-glib-dev is
# what ffmpeg_kit_flutter_new adds to them, and patchelf is what
# linux/bundle-ffmpeg-libraries.sh needs. The second is the codec libraries
# the plugin's prebuilt FFmpeg was linked against: the build copies them into
# the bundle, so they have to be here to be copied. The XDG desktop portal
# and its GTK backend are where file_picker gets a dialog from on Linux; a
# desktop has them, a container does not. The rest is only for trying the
# result: a virtual display, a way to drive it and to photograph it, a
# session bus so that the one-copy-at-a-time rule has something to register
# on, and fonts. The system ffmpeg is in that last group too: the end-to-end
# test uses it to make a sample and to measure what the app made of it. The
# app never sees it; it runs the copy in its bundle.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip xz-utils zip rsync \
        clang cmake ninja-build pkg-config patchelf \
        libgtk-3-dev libjson-glib-dev liblzma-dev libstdc++-12-dev \
        libass9 libmp3lame0 libnuma1 libogg0 libopencore-amrnb0 libopus0 \
        libshine3 libsnappy1v5 libsoxr0 libspeex1 libtheora0 libtwolame0 \
        libvidstab1.1 libvo-amrwbenc0 libvorbis0a libvorbisenc2 libvpx7 \
        libwebp7 libwebpmux3 libx265-199 libxml2 libxvidcore4 \
        xdg-desktop-portal xdg-desktop-portal-gtk \
        xvfb xdotool imagemagick dbus-x11 \
        ffmpeg \
        libgl1-mesa-dri libegl1 \
        fonts-noto-core fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# Root certificates the host trusts and the image would not: an antivirus or a
# proxy that inspects HTTPS signs every site with a root of its own, and then
# cloning Flutter and downloading FFmpeg fail on verification. Drop the root as
# a PEM .crt into extra-ca/, which git ignores, rather than switching
# verification off. The README in that folder says how to export one.
COPY extra-ca/ /usr/local/share/ca-certificates/extra/
RUN update-ca-certificates

# Same uid as the WSLg sockets, so a window can be shown on the Windows
# desktop from inside the container.
RUN useradd --create-home --uid ${USER_ID} builder \
    && mkdir -p /opt/flutter /work /out \
    && chown builder:builder /opt/flutter /work /out
USER builder
# Made here so that the volume mounted over it starts out owned by builder.
RUN mkdir -p /home/builder/.pub-cache

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
        https://github.com/flutter/flutter.git /opt/flutter
ENV PATH=/opt/flutter/bin:/home/builder/.pub-cache/bin:${PATH}
RUN flutter config --no-analytics --enable-linux-desktop \
    && flutter precache --linux

COPY --chown=builder:builder container.sh /usr/local/bin/silence-speedup
WORKDIR /work
ENTRYPOINT ["bash", "/usr/local/bin/silence-speedup"]
CMD ["build"]
