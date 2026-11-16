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

# Wrapper for localectl, e.g. set-x11-keymap it pc105 "" (use --help)
[group('System')]
[positional-arguments]
keyboard-language *args:
    sudo localectl  "$@"

# Args: name = key file (~/.ssh/id_ed25519_<name>), label = this machine's name
# in the key comment (user@label-date), target = user@host for ssh-copy-id.
# An existing key is reused, not overwritten: run again with the same <name>
# and another <target> to put the same key on a second server (rpi2 and rpi5).

# Create an SSH key, ssh-copy-id it to a server, print the ~/.ssh/config snippet
[group('System')]
[positional-arguments]
ssh-setup-key name label target:
    #!/usr/bin/bash
    set -euo pipefail
    name="$1"; label="$2"; target="$3"
    key="$HOME/.ssh/id_ed25519_${name}"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ -e "$key" ]]; then
        echo "Key $key already exists, reusing it."
    else
        ssh-keygen -t ed25519 -a 100 \
            -C "${USER}@${label}-$(date +%Y%m%d)" \
            -f "$key"
    fi

    ssh-copy-id -i "${key}.pub" "$target"

    host="${target#*@}"
    echo
    echo "Add this to ~/.ssh/config:"
    echo
    echo "Host ${host}"
    echo "    HostName ${host}"
    if [[ "$target" == *@* ]]; then
        echo "    User ${target%@*}"
    fi
    echo "    IdentityFile ${key}"
    echo "    IdentitiesOnly yes"