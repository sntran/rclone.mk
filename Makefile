#!/usr/bin/make -rRf

# Ensures each Make recipe is ran as one single shell session
.ONESHELL:
MAKEFLAGS += --warn-undefined-variables
# Make was made for compiling C, so there are a lot of built-in rules for it. We don't need them.
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
# Disabling of built-in rules by writing an empty rule for .SUFFIXES
.SUFFIXES:

# Variables that can be overriden through command line.
TRANSFERS = 8
ACCOUNTS = accounts/*.json

.PHONY: rclone
# Installs rclone
rclone:
	@curl https://rclone.org/install.sh | sudo bash -s beta
	
.PRECIOUS: $(wildcard *.conf)

# Performs a rclone sync on a config file.
# The config file should define at least a "source" and "target" remotes.
%.conf: $(sort $(wildcard $(ACCOUNTS)))
	$(call rsync,"$@",$?)

# HELPERS

# Recursively touchs a file.
define rtouch
	@touch $(word 1,$1)
	$(if $(word 2,$1),$(call rtouch,$(wordlist 2,$(words $1),$1)))
endef

# Recursively sync using a config file with "source" and "target" remotes.
# @param {string} $1 - Path to config file with "source" and "target" remotes defined.
# @param {wodlist} $3 - The list of all service account files newer than config file.
define rsync
	@rclone --config=$(strip $1) config update target service_account_file $(word 1,$2)

	@sleep 1
	-$(call rtouch,$2)

	-rclone --config=$(strip $1) \
		sync source: target: \
		--progress --quiet \
		--cutoff-mode=soft \
		--buffer-size 128M \
		--transfers=$(TRANSFERS)

	-touch "$(strip $1)"
	@sleep 1
	-$(call rtouch,$(wordlist 2,$(words $2),$2))

	$(if $(word 2,$2),$(call rsync,$1,$(wordlist 2,$(words $2),$2)))
endef

# Recursive wildcard function to find a pattern inside a folder.
# Example: $(call rwildcard,css,*.scss)
rwildcard = $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# Returns all whitespace-separated words in $2 that are after $1.
after = $(if $(findstring $1,$2),\
	$(call after,$1,$(wordlist 2,$(words $2),$2)),\
	$2\
)
