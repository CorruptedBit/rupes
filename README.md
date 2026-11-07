# rupes

A personal [bootc](https://github.com/bootc-dev/bootc) image: Fedora Atomic with the **OGC gaming
kernel swapped in**, plus opinionated dev tooling.

Published at: `ghcr.io/corruptedbit/rupes`

## What's in the image

- **Base**: a [Fedora Atomic Desktop](https://fedoraproject.org/atomic-desktops/) variant —
  see the DE-specific flavor branch (`sway`, `gnome`, ...) for which one and its desktop-specific
  configuration.
- **OGC kernel swap**: Fedora's stock kernel is removed and replaced with the
  [OGC kernel](https://github.com/OpenGamingCollective/linux) (BORE/LAVD schedulers,
  SteamOS-derived tuning), pulled prebuilt from the `ghcr.io/ublue-os/akmods` images — see
  [`build_files/install-kernel-akmods`](./build_files/install-kernel-akmods). Also includes the
  `xone` kmod (Xbox controller driver); more prebuilt kmods can be uncommented there (OpenRazer,
  v4l2loopback, EVDI, ...).
- **Gaming basics baked into the image**: `gamemode`, `mesa-vulkan-drivers` — plain Fedora
  packages, no COPR/RPM Fusion required. `gamescope`/`mangohud` are intentionally left out
  (Steam runs as a Flatpak, which uses its own sandbox extensions for them).
- **`ratbagd`** (`libratbag-ratbagd`): D-Bus daemon for configuring gaming mice, used by Piper.
- **Steam**: intentionally *not* baked in — installed on demand via `hjust install-steam`
  (Flatpak/Flathub), the well-supported path for Steam on an immutable/ostree base.
- Similar to [uCore](https://github.com/ublue-os/ucore): `podman-compose`, `firewalld`,
  `tailscale`, `distrobox`
- **Zed** editor (via the [Terra](https://terra.fyi/) repo, enabled only during the build)
- **Custom Nerd Fonts**: CascadiaCode, FantasqueSansMono, Mononoki
- **Flatpak**, with Flathub pre-configured as a system remote on first boot
- **Homebrew** (via [ublue-os/brew](https://github.com/ublue-os/brew)), extracted on first boot,
  with automatic daily update/upgrade timers
- **`just`** (plain, from Fedora's repos — no `ujust`), reachable from any shell via the
  `hjust` alias:
  - `hjust enable-<tool>` / `disable-<tool>` — idempotent install/uninstall via Homebrew, one
    pair per tool: `claude-code`, `git-graph`, `zellij`, `chezmoi`, `starship` (also wires/unwires
    the `eval "$(starship init bash)"` line in `~/.bashrc`). Actual dotfiles (e.g.
    `~/.config/starship.toml`) are out of scope here — manage them with `chezmoi`.
  - `hjust install-steam` — installs Steam via Flatpak/Flathub
  - `hjust kernel-info` — prints `uname -r` to confirm the OGC kernel swap took
  - `hjust update` — `sudo bootc upgrade`
  - `hjust clean` — prunes dangling/unused Podman images

**Not included**: Waydroid/Android support, Input Remapper, container/pod GUI management tools,
vkBasalt, OBS VkCapture. Add them yourself in `build_files/build.sh` if you end up wanting them.

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
  `ghcr.io/ublue-os/akmods{,-extra}:ogc-45` images, then runs `build.sh` against the DE-specific
  base image declared in the flavor branch (`sway`, `gnome`, ...) — this `core` branch has no
  base image `FROM` line and is not meant to be built directly.
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
  fonts, custom `just` recipes (including `gaming.just`), `hjust` binary. Merged into
  `/` by `build.sh`, not by a separate `COPY` in the `Containerfile`.
- **`env/core-image-template.env`** / **`env/branch-image-template.env`** — build metadata, loaded
  together by the `Justfile` via `set dotenv-command` (`cat` of both files). `core-image-template.env`
  holds values shared by every flavor (`REPO_ORGANIZATION`, `CORE_VERSION`, ...);
  `branch-image-template.env` holds DE-specific ones (`IMAGE_NAME`, `BRANCH_VERSION`, ...) — see
  "Image tagging scheme" below.
- **`Justfile`** — local build/test commands (see below).
- **`disk_config/`** — `bootc-image-builder` configs:
  - `disk.toml` — for `qcow2`/`raw` VM images (20 GiB filesystem minimum).
  - `iso.toml` — for the bare-metal/VM installer ISO. Its kickstart `%post` runs `bootc switch`
    to this image's `ghcr.io` tag once Anaconda finishes installing the base OS. Note:
    `bootc-image-builder`'s `anaconda-iso` type **always partitions automatically**, it is not a
    fully interactive installer like the official Fedora/Bazzite media.

## Branches and commit conventions

The repo is split across three branches:

- **`core`** — the DE-agnostic baseline (kernel swap, dev tooling, fonts, Homebrew, Justfile,
  cosign, ...). No base image `FROM` line in the `Containerfile`, so it's not meant to be built
  directly (`just build` refuses to run on it).
- **`sway`**, **`gnome`** — one per desktop flavor. Each adds its own base image `FROM` line plus
  DE-specific `system_files/`/`build_files/build.sh` entries on top of `core`.

A change that applies to every flavor is committed on `core`, then merged forward:

```bash
git checkout sway && git merge core
git checkout gnome && git merge core
```

A change specific to one DE (e.g. a Sway keybinding) is committed directly on that flavor branch
and never merged into the others.

Commit messages follow a loose Conventional Commits style: `feature:`, `fix:`, `chore:`,
`refactor:`, `bump:`, `doc:`. Commits made directly on a flavor branch add that branch as a scope
— `feature(sway): ...`, `fix(gnome): ...` — so the log makes it obvious which commits are
DE-local versus inherited from `core` via merge. Commits on `core` stay unscoped. Merge commits
keep git's default message (e.g. `Merge branch 'core' into sway`), no prefix needed.

Git tags follow `<branch>/<fedora-major>.<core-version>[.<branch-version>]` (no `<branch-version>`
on `core`, since it never ships an image on its own) — see "Image tagging scheme" below. Create
one with `just git-tag-release` (add `push` to also push it: `just git-tag-release push`).

## Pinning the kernel version

The `Containerfile` uses the floating `ogc-45` tag from `ghcr.io/ublue-os/akmods`, so every
rebuild picks up whatever OGC kernel build is currently published for Fedora 45. For a fully
reproducible/pinned build, list available tags and set `KERNEL_TAG` explicitly:

```bash
skopeo list-tags docker://ghcr.io/ublue-os/akmods | grep ogc-45
podman build --build-arg KERNEL_TAG=ogc-45-7.0.9-ogc3.2.fc45.x86_64 ...
```

## Building and pushing locally

This image is currently built and published entirely from a local machine — no CI/GitHub Actions
involved for now.

Requires [`just`](https://just.systems/) and `podman`.

```bash
# Everything in one go -- no arguments needed: builds, rechunks, tags,
# pushes and signs under the full tagging scheme (see below). The version
# tag is computed once at the start, so all steps share the same date.
just release

# Or step by step. `push` and `sign` have no default arguments on purpose:
# pass the image name and the exact tag (see `sudo podman images`).
just build <image-name> <tag>
sudo just ostree-rechunk <image-name> <tag>
just push <image-name> <tag>
sudo just sign <image-name> <tag>
```

### Image tagging scheme

Each `just release` pushes the same build under three tags:

- `<image-name>:<fedora-major>.<core-version>.<branch-version>.<date>` — exact, immutable build
  (e.g. `45.1.0.20261104`). `<core-version>` comes from `CORE_VERSION` in
  `env/core-image-template.env` (bumped on a substantial change made on `core`, inherited by
  every flavor via `git merge core`); `<branch-version>` comes from `BRANCH_VERSION` in
  `env/branch-image-template.env` (bumped on a substantial change made directly on that flavor
  branch). Both reset to `0` on a Fedora major bump. `<date>` is just the build date, so it never
  needs tracking.
- `<image-name>:<fedora-major>-latest` — floating; always the newest build for that Fedora major.
  Use this to track updates without ever crossing a major Fedora version
  (`bootc switch ghcr.io/corruptedbit/rupes:45-latest`).
- `<image-name>:latest` — floating; always the newest build overall, including major bumps.

`<image-name>` is `IMAGE_NAME` in `env/branch-image-template.env` — each DE flavor publishes to
its own GHCR package (`rupes-sway` for sway, `rupes-gnome` for gnome, ...) so they never collide.
The same version string, followed by the git short SHA (e.g. `45.1.0.20261107-b6aa44d`), is
stored in the image's `org.opencontainers.image.version` label, which is what
`rpm-ostree status` / `bootc status` show as the image version.

All three point at the same image digest, so only one needs to be cosign-signed; verification
against any of the three tags works.

The matching git tag for a given build is `<branch>/<fedora-major>.<core-version>.<branch-version>`
(see "Branches and commit conventions" above) — created with `just git-tag-release`.

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

This repository started from [ublue-os/image-template](https://github.com/ublue-os/image-template).
A copy of the original template README is kept at [`README-ublue.md`](./README-ublue.md) for
reference on generic bootc-image-template usage (cosign setup, ArtifactHub indexing, full
`Justfile` recipe reference, etc.).

A few ideas were borrowed from [ublue-os/bazzite](https://github.com/ublue-os/bazzite): the
kernel-swap approach (`build_files/install-kernel-akmods`, `install-kmods`, `cleanup`) is adapted
directly from its `Containerfile`, and `hjust` (a plain `just` alias, see
[`system_files/usr/bin/hjust`](./system_files/usr/bin/hjust)) takes its shape from Bazzite's own
`ujust` wrapper.
