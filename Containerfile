# Build args used in FROM lines must be declared before the first FROM to be
# visible to it (ARGs after a FROM are scoped to that stage only).
#
# "ogc-44" is a floating tag (always the latest OGC build for Fedora 44).
# For a fully reproducible/pinned build, replace it with an exact tag like
# "ogc-44-7.0.9-ogc3.2.fc44.x86_64" -- list available tags with:
#   skopeo list-tags docker://ghcr.io/ublue-os/akmods | grep ogc-44
ARG FEDORA_VERSION="44"
ARG KERNEL_FLAVOR="ogc"
ARG KERNEL_TAG="${KERNEL_FLAVOR}-${FEDORA_VERSION}"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Prebuilt OGC (Open Gaming Collective) kernel + kernel modules, same akmods
# images ublue-os/bazzite builds its own kernel swap from:
# https://github.com/ublue-os/kernel-cache
FROM ghcr.io/ublue-os/akmods:${KERNEL_TAG} AS akmods
FROM ghcr.io/ublue-os/akmods-extra:${KERNEL_TAG} AS akmods-extra

# Base Image
FROM quay.io/fedora-ostree-desktops/sway-atomic:${FEDORA_VERSION}
## Other possible base images include:
# FROM quay.io/fedora-ostree-desktops/kinoite:44
# FROM quay.io/fedora-ostree-desktops/silverblue:44
# FROM quay.io/fedora/fedora-bootc:44
#
# Fedora Atomic Desktops: quay.io/fedora-ostree-desktops/<variant>-atomic

### KERNEL SWAP
## Rips out Fedora's stock kernel and installs the prebuilt OGC gaming kernel
## (BORE/LAVD schedulers, SteamOS-derived tuning) from the akmods images above.
## Also pulls in the "xone" kmod (Xbox controller driver) -- see
## build_files/install-kernel-akmods to add more prebuilt kmods.
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=akmods,src=/rpms/common,dst=/tmp/rpms/common \
    --mount=type=bind,from=akmods,src=/rpms/kmods,dst=/tmp/rpms/kmods \
    --mount=type=bind,from=akmods-extra,src=/rpms/extra,dst=/tmp/rpms/extra \
    --mount=type=bind,from=akmods-extra,src=/rpms/kmods,dst=/tmp/rpms/kmods-extra \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/install-kernel-akmods && \
    /ctx/cleanup

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN fc-cache -f /usr/share/fonts/

### Homebrew (see https://github.com/ublue-os/brew)
# Copy Homebrew files from the brew image and enable the setup/update/upgrade services.
# Actual extraction to /var/home/linuxbrew/.linuxbrew happens on first boot via brew-setup.service.
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /usr/bin/systemctl preset brew-setup.service && \
    /usr/bin/systemctl preset brew-update.timer && \
    /usr/bin/systemctl preset brew-upgrade.timer

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
