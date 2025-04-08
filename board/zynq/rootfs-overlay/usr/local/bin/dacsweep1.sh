#!/bin/bash

source dac2_config.sh

# DEFINE CONSTANTS
SPI_FREQ_HZ=2000000  # AD5791 SPI_CLK (2 MHz)
SWEEP_GEN_FREQ_HZ=1000000  # Frequency of divided_clk in sweep_generator (1 MHz)

# The output limiter module takes a 24-bit signed number for the upper and lower limits:
MIN_24BIT=-$((2**23))
MAX_24BIT=$((2**23 - 1))
# The sweep module takes a 20-bit signed number for the max and min values:
MIN_20BIT=-$((2**19))
MAX_20BIT=$((2**19 - 1))

# DAC1 has an output range of +/-1V (before the gain amplifer)
OUTPUT_RANGE_MAX=1.0
OUTPUT_RANGE_MIN=-1.0

# Prompt the user for input parameters
read -p "Enter the CENTER value: " CENTER
read -p "Enter the AMPLITUDE value: " AMPLITUDE
read -p "Enter the FREQUENCY value: " FREQUENCY

# Print a separator
echo "------------------------------------------"

# Calculate max and min voltage
maxVoltage=$(echo "$CENTER + $AMPLITUDE" | bc)
minVoltage=$(echo "$CENTER - $AMPLITUDE" | bc)

# Apply voltage clamping
if (( $(echo "$maxVoltage > $OUTPUT_RANGE_MAX" | bc -l) )); then
    echo "Warning: max peak voltage entered ($maxVoltage V) has been clamped to $OUTPUT_RANGE_MAX V"
    maxVoltage=$OUTPUT_RANGE_MAX
fi

if (( $(echo "$minVoltage < $OUTPUT_RANGE_MIN" | bc -l) )); then
    echo "Warning: min peak voltage entered ($minVoltage V) has been clamped to $OUTPUT_RANGE_MIN V"
    minVoltage=$OUTPUT_RANGE_MIN
fi

# Do a linear remapping of the sweep voltage value [0.0, 5.0] to the 20-bit digital value range [-524288, 524287]:
digitalSweepMax=$(echo "$MIN_20BIT + (($maxVoltage - $OUTPUT_RANGE_MIN) * ($MAX_20BIT - $MIN_20BIT)) / ($OUTPUT_RANGE_MAX - $OUTPUT_RANGE_MIN)" | bc)
digitalSweepMin=$(echo "$MIN_20BIT + (($minVoltage - $OUTPUT_RANGE_MIN) * ($MAX_20BIT - $MIN_20BIT)) / ($OUTPUT_RANGE_MAX - $OUTPUT_RANGE_MIN)" | bc)

# Convert digital values to integers
digitalSweepMax=$(printf "%.0f" "$digitalSweepMax")
digitalSweepMin=$(printf "%.0f" "$digitalSweepMin")

# Calculate step size
stepSize=$(echo "($FREQUENCY * ($digitalSweepMax - $digitalSweepMin) * $SPI_FREQ_HZ) / ($SWEEP_GEN_FREQ_HZ^2)" | bc)
stepSize=$(printf "%.0f" "$stepSize")  # Convert to integer

# Debugging Output (Optional)
echo "Analog Center: $CENTER"
echo "Analog Amplitude: $AMPLITUDE"
echo "Analog Frequency (Hz): $FREQUENCY"
echo "Step Size: $stepSize"

# By default set the limit module to the full output range of the 20-bit DAC:
maxLimit=1.0
minLimit=-1.0

# Do a linear remapping of the limiter voltage value [0.0, 5.0] to the 24-bit digital value [-8388608, 8388607]:
limitMaxVal=$(echo "$MIN_24BIT + (($maxLimit - $OUTPUT_RANGE_MIN) * ($MAX_24BIT - $MIN_24BIT)) / ($OUTPUT_RANGE_MAX - $OUTPUT_RANGE_MIN)" | bc)
limitMinVal=$(echo "$MIN_24BIT + (($minLimit - $OUTPUT_RANGE_MIN) * ($MAX_24BIT - $MIN_24BIT)) / ($OUTPUT_RANGE_MAX - $OUTPUT_RANGE_MIN)" | bc)

# Write to Output limit max and min values to BRAM
devmem2_write 597 $((limitMaxVal & 0xFFFF))          # Sets the limiter max_in[15:0] at bram addr = 725
devmem2_write 598 $(((limitMaxVal >> 16) & 0xFF))    # Sets the limiter max_in[24:16] at bram addr = 726
devmem2_write 599 $((limitMinVal & 0xFFFF))          # Sets the limiter min_in[15:0] at bram addr = 727
devmem2_write 600 $(((limitMinVal >> 16) & 0xFF))    # Sets the limiter min_in[24:16] at bram addr = 728

# Set Sweep Generator MAX
devmem2_write 591 $((digitalSweepMax & 0xFFFF))  # Sets the sweep generator max_in[15:0]
devmem2_write 592 $(((digitalSweepMax >> 16) & 0xFF)) # Sets the sweep generator max_in[19:16]

# Set Sweep Generator MIN
devmem2_write 593 $((digitalSweepMin & 0xFFFF)) # Sets the sweep generator min_in[15:0]
devmem2_write 594 $(((digitalSweepMin >> 16) & 0xFF)) # Sets the sweep generator min_in[19:16]

# Set Sweep Generator STEP_SIZE
devmem2_write 595 $stepSize

# Enable Sweep Generator:
devmem2_write 577 1