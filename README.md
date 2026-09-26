# rupes

A personal [bootc](https://github.com/bootc-dev/bootc) image: Fedora Atomic with the **OGC gaming
kernel swapped in**, plus opinionated dev tooling. Built from scratch rather than by extending
[Bazzite](https://github.com/ublue-os/bazzite) directly — same kernel/gaming-driver source (the
`ublue-os/akmods` images), none of Bazzite's Android/Waydroid or container-GUI-management bloat.

Published at: `ghcr.io/corruptedbit/rupes`

## Philosophy

This is the gaming-capable sibling of [fedora-dev-light](https://github.com/corruptedbit/fedora-dev-light):
same base image, same `hjust`-based automation, same dev tooling — plus a kernel swap and a
minimal, on-demand gaming stack. Nothing here is Bazzite-specific or `ujust`-based.

## What's in the image

- **Base**: [Fedora Sway Atomic](https://quay.io/repository/fedora-ostree-desktops/sway-atomic) —
  a complete, minimal Wayland setup (Sway compositor, waybar, launcher, terminal, ...)
- **OGC kernel swap**: Fedora's stock kernel is removed and replaced with the
  [OGC kernel](https://github.com/OpenGamingCollective/linux) (BORE/LAVD schedulers,
  SteamOS-derived tuning), pulled prebuilt from the same `ghcr.io/ublue-os/akmods` images
  Bazzite itself builds from — see [`build_files/install-kernel-akmods`](./build_files/install-kernel-akmods).
  Also includes the `xone` kmod (Xbox controller driver); more prebuilt kmods can be
  uncommented there (OpenRazer, v4l2loopback, EVDI, ...).
- **Gaming basics baked into the image**: `gamemode`, `mesa-vulkan-drivers` — plain Fedora
  packages, no COPR/RPM Fusion required. `gamescope`/`mangohud` are intentionally left out
  (Steam runs as a Flatpak, which uses its own sandbox extensions for them).
- **`ratbagd`** (`libratbag-ratbagd`): D-Bus daemon for configuring gaming mice, used by Piper.
- **Steam**: intentionally *not* baked in — installed on demand via `hjust install-steam`
  (Flatpak/Flathub), the well-supported path for Steam on an immutable/ostree base.
- Similar to [uCore](https://github.com/ublue-os/ucore): `podman-compose`, `firewalld`,
  `tailscale`, `distrobox`
- **Visual Studio Code** (from Microsoft's official repo)
- **Zed** editor (via the [Terra](https://terra.fyi/) repo, enabled only during the build)
- **Custom Nerd Fonts**: CascadiaCode, FantasqueSansMono, Mononoki
- **Flatpak**, with Flathub pre-configured as a system remote on first boot
- **Homebrew** (via [ublue-os/brew](https://github.com/ublue-os/brew)), extracted on first boot,
  with automatic daily update/upgrade timers
- **`just`** (plain, from Fedora's repos — no `ujust`), reachable from any shell via the
  `hjust` alias:
  - `hjust install-dev-tools` — Claude Code, starship, git-graph, zellij (via Homebrew)
  - `hjust enable-starship` — wires up starship in `~/.bashrc`
  - `hjust install-steam` — installs Steam via Flatpak/Flathub
  - `hjust kernel-info` — prints `uname -r` to confirm the OGC kernel swap took
  - `hjust update` — `sudo bootc upgrade`
  - `hjust clean` — prunes dangling/unused Podman images
- **Custom wallpaper** ("Rancho") under `/usr/share/wallpapers`

**Deliberately not included** (unlike Bazzite): Waydroid/Android support, Input Remapper,
container/pod GUI management tools, vkBasalt, OBS VkCapture. Add them yourself in
`build_files/build.sh` if you end up wanting them.

All package installation logic lives in [`build_files/build.sh`](./build_files/build.sh), invoked
from the [`Containerfile`](./Containerfile) during the image build. The kernel swap is a separate
`RUN` step earlier in the `Containerfile`, using [`build_files/install-kernel-akmods`](./build_files/install-kernel-akmods).

## Switching to this image

From a system already running a bootc image (Fedora Atomic, Bazzite, Bluefin, Aurora, ...):

```bash
sudo bootc switch ghcr.io/corruptedbit/rupes:latest
```

Reboot to apply.

## Repository layout

- **`Containerfile`** — entrypoint for the image build. Pulls in `build_files/` and
  `system_files/` via a `FROM scratch` context stage (`ctx`), swaps in the OGC kernel from the
  `ghcr.io/ublue-os/akmods{,-extra}:ogc-44` images, then runs `build.sh` against the
  `quay.io/fedora-ostree-desktops/sway-atomic:44` base image.
- **`build_files/install-kernel-akmods`** — removes Fedora's stock kernel, installs the prebuilt
  OGC kernel RPMs, versionlocks them so `dnf` never reinstalls the stock kernel, and installs a
  small set of prebuilt kmods (only `xone` by default).
- **`build_files/install-kmods`** — helper used by `install-kernel-akmods` to install whichever
  kmod RPM globs are actually present (skips missing ones instead of failing the build).
- **`build_files/cleanup`** — clears build-time caches/tmp/`/boot` leftovers after the kernel swap
  layer (bootc regenerates `/boot` from `/usr/lib/modules` at deploy time).
- **`build_files/build.sh`** — installs packages (gaming basics, dev tooling, Flatpak/Flathub,
  `just`), copies `system_files/` into the image root, enables `podman.socket` +
  `flathub-setup.service`.
- **`system_files/`** — mirrors the final image's root filesystem: Flathub remote definition,
  fonts, wallpaper, custom `just` recipes (including `gaming.just`), `hjust` binary. Merged into
  `/` by `build.sh`, not by a separate `COPY` in the `Containerfile`.
- **`image-template.env`** — build metadata, loaded by the `Justfile` via `set dotenv-filename`.
- **`Justfile`** — local build/test commands (see below).
- **`disk_config/`** — `bootc-image-builder` configs:
  - `disk.toml` — for `qcow2`/`raw` VM images (20 GiB filesystem minimum).
  - `iso.toml` — for the bare-metal/VM installer ISO. Its kickstart `%post` runs `bootc switch`
    to this image's `ghcr.io` tag once Anaconda finishes installing the base OS. Note:
    `bootc-image-builder`'s `anaconda-iso` type **always partitions automatically**, it is not a
    fully interactive installer like the official Fedora/Bazzite media.

## Pinning the kernel version

The `Containerfile` uses the floating `ogc-44` tag from `ghcr.io/ublue-os/akmods`, so every
rebuild picks up whatever OGC kernel build is currently published for Fedora 44. For a fully
reproducible/pinned build, list available tags and set `KERNEL_TAG` explicitly:

```bash
skopeo list-tags docker://ghcr.io/ublue-os/akmods | grep ogc-44
podman build --build-arg KERNEL_TAG=ogc-44-7.0.9-ogc3.2.fc44.x86_64 ...
```

## Building and pushing locally

This image is currently built and published entirely from a local machine — no CI/GitHub Actions
involved for now.

Requires [`just`](https://just.systems/) and `podman`.

```bash
# Build the image
just build rupes latest

# Optional: rechunk for smaller incremental updates
sudo just ostree-rechunk rupes latest

# Push to GHCR
just push rupes latest

# Sign the image (requires cosign.key locally)
sudo just sign rupes latest

# Or do all of the above in one go
just release rupes latest
```

### Building a VM image or ISO

```bash
# QCOW2 for a VM
just build-qcow2 rupes latest

# Bare-metal/VM installer ISO (points at the local build by default;
# pass a ghcr.io/... reference to build straight from the published image)
just build-iso rupes latest
```

## Container signing

Builds are meant to be signed locally with [cosign](https://docs.sigstore.dev/cosign/overview/)
via `just sign` (see above). This repo does **not** ship a `cosign` keypair yet — generate your
own before the first signed release:

```bash
cosign generate-key-pair
```

Keep `cosign.key` local and gitignored (already covered by `.gitignore`); commit `cosign.pub` so
pulled images can be verified.

## Credit

This repository started from [ublue-os/image-template](https://github.com/ublue-os/image-template),
via [fedora-dev-light](https://github.com/corruptedbit/fedora-dev-light). The kernel-swap approach
(`build_files/install-kernel-akmods`, `install-kmods`, `cleanup`) is adapted directly from
[ublue-os/bazzite](https://github.com/ublue-os/bazzite)'s own `Containerfile`. A copy of the
original template README is kept at [`README-ublue.md`](./README-ublue.md) for reference on
generic bootc-image-template usage (cosign setup, ArtifactHub indexing, full `Justfile` recipe
reference, etc.).

The Sway/Waybar/fuzzel theming took visual inspiration from
[Coutons/sway-ricing](https://github.com/Coutons/sway-ricing); no files were copied from it.
