# Tool install/uninstall recipes, one pair per tool. All via Homebrew (see
# https://github.com/ublue-os/brew): `brew` itself is only extracted to
# /var/home/linuxbrew/.linuxbrew on first boot by brew-setup.service.
#
# Every enable/disable recipe is idempotent.

[group('Tools')]
enable-claude-code:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --cask claude-code &>/dev/null; then
        echo "claude-code is already installed."
    else
        brew install --cask claude-code
    fi

[group('Tools')]
disable-claude-code:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --cask claude-code &>/dev/null; then
        brew uninstall --cask claude-code
    else
        echo "claude-code is not installed."
    fi

[group('Tools')]
enable-git-graph:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --formula git-graph &>/dev/null; then
        echo "git-graph is already installed."
    else
        brew install git-graph
    fi

[group('Tools')]
disable-git-graph:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --formula git-graph &>/dev/null; then
        brew uninstall git-graph
    else
        echo "git-graph is not installed."
    fi

[group('Tools')]
enable-zellij:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --formula zellij &>/dev/null; then
        echo "zellij is already installed."
    else
        brew install zellij
    fi

[group('Tools')]
disable-zellij:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --formula zellij &>/dev/null; then
        brew uninstall zellij
    else
        echo "zellij is not installed."
    fi

[group('Tools')]
enable-chezmoi:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --formula chezmoi &>/dev/null; then
        echo "chezmoi is already installed."
    else
        brew install chezmoi
    fi

[group('Tools')]
disable-chezmoi:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --formula chezmoi &>/dev/null; then
        brew uninstall chezmoi
    else
        echo "chezmoi is not installed."
    fi

# Install starship and wire it into ~/.bashrc. The prompt theme itself is a
# dotfile (~/.config/starship.toml) and belongs to your chezmoi setup, not here.
[group('Tools')]
enable-starship:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --formula starship &>/dev/null; then
        echo "starship is already installed."
    else
        brew install starship
    fi
    if grep -qF 'eval "$(starship init bash)"' ~/.bashrc 2>/dev/null; then
        echo "starship is already enabled in ~/.bashrc."
    else
        printf '\n# Starship\neval "$(starship init bash)"\n' >> ~/.bashrc
        echo "starship enabled. Run 'source ~/.bashrc' or restart your shell to apply."
    fi

[group('Tools')]
disable-starship:
    #!/usr/bin/bash
    set -euo pipefail
    if brew list --formula starship &>/dev/null; then
        brew uninstall starship
    else
        echo "starship is not installed."
    fi
    if grep -qF 'eval "$(starship init bash)"' ~/.bashrc 2>/dev/null; then
        sed -i '/^# Starship$/d; /eval "\$(starship init bash)"/d' ~/.bashrc
        echo "starship lines removed from ~/.bashrc."
    else
        echo "~/.bashrc has no starship lines."
    fi
