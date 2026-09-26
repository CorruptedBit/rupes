# Install dev tools via Homebrew
[group('Dev Tools')]
install-dev-tools:
	brew install --cask claude-code
	brew install starship git-graph zellij

# Enable starship in bash
[group('Dev Tools')]
enable-starship:
    #!/usr/bin/bash
    if grep -q 'eval "$(starship init bash)"' ~/.bashrc 2>/dev/null; then
        echo "Starship is already enabled in ~/.bashrc."
    else
        echo '# Starship' >> ~/.bashrc
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
        echo "Starship enabled. Run 'source ~/.bashrc' or restart your shell to apply."
        echo "Remove starship related lines from ~/.bashrc to disable it."
    fi
