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
