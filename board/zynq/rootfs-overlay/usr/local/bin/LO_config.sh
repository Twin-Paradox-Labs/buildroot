#!/bin/bash

source dac2_config.sh

FPGA_CLK_FREQ=100000000 # 100MHz
DDS_PHASE_WIDTH=24
#ACCUM_SIZE=$(echo "2^$DDS_PHASE_WIDTH" | bc)


if [ $# -lt 3 ]; then
  echo "Usage: $0 <LO_freq_HZ> <LO_gain_shift> <DAC_channel>"
  echo "<LO_freq_HZ> is the LO frequency (pinc input to DDS)"
  echo "<LO_gain_shift> is gain amount on the LO amplitude. Ampltidue is shifted right, this is the number of bits to keep."
  echo "<DAC_channel> specifies which DAC output to apply the modulation to"
  exit 
fi

FREQ=$1
BITS_TO_KEEP=$2
DAC_CHANNEL=$3

if [ "$BITS_TO_KEEP" -gt 24 ] || [ "$BITS_TO_KEEP" -lt 0 ]; then
    echo "<LO_gain_shift> must be between 0 and $DDS_PHASE_WIDTH"
    exit 1
fi

# All 3 DACs share the DDS frequency BRAM register because there is only one DDS
# The output frequency of the DDS sine wave can be calcualtor from this formula:
# DDS_OUT_FREQ = (PINC * FPGA_FREQ)/(2^NUM_BITS)
PINC=$(echo "scale=10; ($FREQ / $FPGA_CLK_FREQ) * (2 ^ $DDS_PHASE_WIDTH)" | bc -l)
PINC_ROUNDED=$(printf "%.0f" "$PINC")
devmem2_write 281 $(($PINC_ROUNDED & 0xFFFF)) # PINC bits [15:0]
devmem2_write 282 $((($PINC_ROUNDED >> 16) & 0xFF)) # PINC bits [15:0]

ACTUAL_FREQ=$(echo "scale=10; ($PINC_ROUNDED*$FPGA_CLK_FREQ) / (2 ^ $DDS_PHASE_WIDTH)" | bc -l )
printf "DDS enabled with output frequency of %.2f Hz\n" $ACTUAL_FREQ

# The LO signal is a 24-bit sine wave. The FPGA sifts this right by a programmable amount
# The number specified here is how many bits to keep out of the 24-bit sine wave
# RIGHT_SHIFT_AMOUNT = 24 - bitsToShift
# This is how many bits you will right shift in the fpga
RIGHT_SHIFT_AMOUNT=$(($DDS_PHASE_WIDTH - $BITS_TO_KEEP))

# Each DAC has its own gain value register: BRAM 456 = DAC0, BRAM 584 = DAC1, BRAM 712 = DAC2 (these regisers are seperate by 128)
devmem2_write $((456 + (128 * $DAC_CHANNEL))) $RIGHT_SHIFT_AMOUNT
