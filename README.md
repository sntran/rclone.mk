# rclone.mk

Utilities for rclone based on Make

## Targets

### `make rclone`

Downloads and installs rclone based on current operating system and architecture.

### `make %.conf`

Performs a `rclone sync` using the config file specified as target.

This config file MUST define at least a "source" and a "target" remotes
At basic level, the recipe will simply do `rclone sync --config $@ source: target:`

However, this recipe supports rotating service accounts. It will update the config
with the next available account before executing the sync.

The target takes a list of service accounts as dependencies, and will update both them 
and the target so that in case of rclone errors out and we have to restart `make`.
When that happens, only unused accounts will be sent as dependencies of the target.
