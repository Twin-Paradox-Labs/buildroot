#!/bin/bash

source dac2_config.sh
# Define constants
SPI_FREQ_HZ=2000000  # AD5791 SPI_CLK (2 MHz)
SWEEP_GEN_FREQ_HZ=1000000  # Frequency of divided_clk in sweep_generator (1 MHz)

OUTPUT_RANGE_MAX=5.0
OUTPUT_RANGE_MIN=-$OUTPUT_RANGE_MAX

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

# Map a value from [-5.0, 5.0] to [-524288, 524287]
DAC_min=-524288  # Digital min value
DAC_max=524287   # Digital max value


digitalSweepMax=$(echo "$DAC_min + (($maxVoltage - $OUTPUT_RANGE_MIN) * ($DAC_max - $DAC_min)) / ($OUTPUT_RANGE_MAX - $OUTPUT_RANGE_MIN)" | bc)
digitalSweepMin=$(echo "$DAC_min + (($minVoltage - $OUTPUT_RANGE_MIN) * ($DAC_max - $DAC_min)) / ($OUTPUT_RANGE_MAX - $OUTPUT_RANGE_MIN)" | bc)

# Convert digital values to integers
digitalSweepMax=$(printf "%.0f" "$digitalSweepMax")
digitalSweepMin=$(printf "%.0f" "$digitalSweepMin")

# Calculate step size
stepSize=$(echo "($FREQUENCY * ($digitalSweepMax - $digitalSweepMin) * $SPI_FREQ_HZ) / ($SWEEP_GEN_FREQ_HZ^2)" | bc)
stepSize=$(printf "%.0f" "$stepSize")  # Convert to integer

# For now, make the limit block have no clipping
limitMinVal=0x8000000
limitMaxVal=0x7ffffff

# Debugging Output (Optional)
echo "Analog Center: $CENTER"
echo "Analog Amplitude: $AMPLITUDE"
echo "Analog Frequency (Hz): $FREQUENCY"
echo "Step Size: $stepSize"

# Write to Output limit max and min values to BRAM
devmem2_write 469 $((limitMaxVal & 0xFFFF))          # Sets the limiter max_in[15:0] at bram addr = 725
devmem2_write 470 $(((limitMaxVal >> 16) & 0xFF))    # Sets the limiter max_in[24:16] at bram addr = 726
devmem2_write 471 $((limitMinVal & 0xFFFF))          # Sets the limiter min_in[15:0] at bram addr = 727
devmem2_write 472 $(((limitMinVal >> 16) & 0xFF))    # Sets the limiter min_in[24:16] at bram addr = 728

# Sets ModSum input to be sum of SWEEPout + TRANSFERmod
#devmem2_write 712 24

# Set Sweep Generator MAX
devmem2_write 463 $((digitalSweepMax & 0xFFFF))  # Sets the sweep generator max_in[15:0]
devmem2_write 464 $(((digitalSweepMax >> 16) & 0xFF)) # Sets the sweep generator max_in[19:16]

# Set Sweep Generator MIN
devmem2_write 465 $((digitalSweepMin & 0xFFFF)) # Sets the sweep generator min_in[15:0]
devmem2_write 466 $(((digitalSweepMin >> 16) & 0xFF)) # Sets the sweep generator min_in[19:16]

# Set Sweep Generator STEP_SIZE
devmem2_write 467 $stepSize

# Enable Sweep Generator:
devmem2_write 449 1
