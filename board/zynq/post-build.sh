#!/bin/sh

# genimage will need to find the extlinux.conf
# in the binaries directory

BOARD_DIR="$(dirname "$0")"

# Comenting this out because we are using a uEnv.txt file instead
#install -m 0644 -D "${BOARD_DIR}/extlinux.conf" "${BINARIES_DIR}/extlinux.conf"

# Make devmem2 executable by non-root via SetUID
chmod 4755 "${TARGET_DIR}/usr/local/bin/devmem2"

# Force correct permissions on /usr/local/bin
chmod 0777 "${TARGET_DIR}/usr/local/bin"

# Add a Buildroot timestamp for version info:
echo "BUILD_TIMESTAMP=\"$(date)\"" >> ${TARGET_DIR}/etc/os-release