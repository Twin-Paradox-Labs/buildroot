#!/bin/bash

# This script is meant to be run on the Zynq, not on the server
# This will read the version registers and convert to human readable format
# FPGA verison registers get populated through the Makefile and build.tcl scripts, 
# if you build using the Vivado GUI these will not be populated

VERSION_REG_BASE_ADDR=$(get_dt_addr version_reg)

timestamp_hex=$(devmem2 $VERSION_REG_BASE_ADDR | awk '/Value at address/ {print $NF}')
timestamp_dec=$(($timestamp_hex))
# Convert the timestamp from a hex value to a human-readable format:
timestamp=$(TZ="EST" date -d "@$timestamp_dec" +"%Y-%m-%d %H:%M:%S %Z")

# Convert hex usr_id to ASCII characters
usr_id_hex=$(devmem2 $(( $VERSION_REG_BASE_ADDR + 4 )) | awk '/Value at address/ {print $NF}')
usr_id_ascii=$(printf "%08x" $((usr_id_hex)) | xxd -r -p)

git_hash=$(devmem2 $(( $VERSION_REG_BASE_ADDR + 8 )) | awk '/Value at address/ {print $NF}')

echo "----------------------------------------------------------------------------"
echo "FPGA version: $timestamp_hex"
echo "FPGA build timestamp: $timestamp"
echo "FPGA build user ID: $usr_id_ascii"
echo "FPGA built from commit: $git_hash"
echo "Kernel version: $(uname -r)"
echo "Rootfs version: $(cat /etc/os-release | grep "BUILD_TIMESTAMP")"
echo "----------------------------------------------------------------------------"
