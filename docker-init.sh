#!/bin/bash -e

# Check to see if the lotus config file exists
if [ ! -f ~/.lotus/config.toml ]; then
  echo "No lotus config file found, will be initialized with this first run."

  # If we've hit this block of code then it's fair to assume lotus has never run
  # before. Syncing lotus can take a very long time. If the user wants we can
  # start lotus with a bootstrap file to speed things up.

  # Does user want us to sync from bootstrap?
  if [ "$SYNC_FROM_BOOTSTRAP_IF_UNINITIALIZED" = true ]; then
    # Start lotus and wait for it to complete the initial bootstrap. It will
    # exit automatically when completed. When the container reboots, lotus
    # will start normally.
    LOTUS_FD_MAX=100000 \
    GOLOG_OUTPUT="file" \
    GOLOG_FILE="/data/lotus/log/lotus.log" \
    GOLOG_LOG_FMT="json" \
    LOTUS_PATH="/root/.lotus" \
    LOTUS_MAX_HEAP="64GiB" \
      lotus daemon \
      --import-snapshot https://fil-chain-snapshots-fallback.s3.amazonaws.com/mainnet/minimal_finality_stateroots_latest.car \
      --halt-after-import
  fi
else
  echo "Lotus configuration discovered, proceeding to normal startup."
  LOTUS_FD_MAX=100000 \
  GOLOG_OUTPUT="file" \
  GOLOG_FILE="/data/lotus/log/lotus.log" \
  GOLOG_LOG_FMT="json" \
  LOTUS_PATH="/root/.lotus" \
  LOTUS_MAX_HEAP="32GiB" \
    lotus daemon
fi
