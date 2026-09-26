# Install Steam via Flatpak (Flathub) -- the well-supported path on an
# immutable/ostree base; the OGC kernel and gamemode are already baked into
# the image itself.
[group('Gaming')]
install-steam:
	flatpak install --system -y flathub com.valvesoftware.Steam
