# Update the base image
[group('System')]
update:
	sudo bootc upgrade

# Prune dangling and unused container images
[group('System')]
clean:
	podman image prune -a -f

# Show which kernel is currently running (confirms the OGC swap took)
[group('System')]
kernel-info:
	uname -r

# Switch to dark mode
[group('Switch')]
switch-to-dark-mode:
    # color-scheme covers GTK4/libadwaita apps and the portal (Flatpak).
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    # gtk-theme is what actually flips plain GTK3 apps (Thunar, Blueman, ...)
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'

# Switch to light mode
[group('Switch')]
switch-to-light-mode:
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
