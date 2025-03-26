#!/bin/bash

source dac2_config.sh

FPGA_CLK_FREQ=100000000 # 100MHz
ACCUM_BITS=24
ACCUM_SIZE=$((1 << $ACCUM_BITS))


if [ $# -lt 2 ]; then
  echo "Usage: $0 <LO_freq_HZ> <LO_gain_shift>"
  echo "<LO_freq_HZ> is the LO frequency (pinc input to DDS)"
  echo "<LO_gain_shift> is gain amount on the LO amplitude. Ampltidue is shifted right, this is the number of bits to keep."
  exit 
fi

FREQ=$1
BITS_TO_KEEP=$2

if [ "$BITS_TO_KEEP" -gt 24 ] || [ "$BITS_TO_KEEP" -lt 0 ]; then
    echo "<LO_gain_shift> must be between 0 and $ACCUM_BITS"
    exit 1
fi

# Compute the phase increment (pinc) = round( (FREQ / FPGA_CLK_FREQ) * 2^24 )
PINCBIG=$(echo "scale=10; ($FREQ * $ACCUM_SIZE) / $FPGA_CLK_FREQ" | bc -l)
PINC=$(echo "$PINCBIG + 0.5" | bc -l | awk '{printf "%d\n",$1}')

# The LO signal is a 24-bit sine wave. The FPGA sifts this right by a programmable amount
# The number specified here is how many bits to keep out of the 24-bit sine wave
# RIGHT_SHIFT_AMOUNT = 24 - bitsToShift
# This is how many bits you will right shift in the fpga
RIGHT_SHIFT_AMOUNT=$(($ACCUM_BITS - $BITS_TO_KEEP))


devmem2_write 281 $FREQ
devmem2_write 712 $RIGHT_SHIFT_AMOUNT
