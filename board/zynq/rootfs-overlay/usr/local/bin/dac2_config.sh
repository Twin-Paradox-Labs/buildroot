#!/bin/bash

# For now, make the limit block have no clipping
limitMinVal=0x8000000
limitMaxVal=0x7ffffff
# Get current timestamp in YYYYMMDD-HHMMSS format
timestr=$(date +"%Y%m%d-%H%M%S")

# Define the log file path
filename="devmem_log/${timestr}_log.txt"

mkdir -p devmem_log

init_channel() {
        echo "Initializing..." 
        devmem2 0x43C00000 h 0x0000 
        devmem2 0x43C00002 h 0x0000 
        devmem2 0x43C00004 h 0x0000 
        devmem2 0x43C00006 h 0x0000 
        echo "Init Completed" 
}

devmem2_write(){
    local bram_addr=$1
    local bram_data=$2	

    init_channel >> "$filename"

    echo -e "\e[34mWriting to BRAM: Address="$bram_addr", Data="$bram_data"\e[0m" >> "$filename"

    devmem2 0x43C00002 h 0x0100 >> "$filename"
    devmem2 0x43C00004 h "$bram_addr" >> "$filename"
    devmem2 0x43C00006 h "$bram_data" >> "$filename"
    devmem2 0x43C00000 h 0x0001 >> "$filename"

}

devmem2_read(){
    local bram_addr=$1

    init_channel >> "$filename"

    echo -e "\e[34mReading BRAM: Address="$bram_addr"\e[0m" >> "$filename"

    devmem2 0x43C00002 h 0x0000  >> "$filename"
    devmem2 0x43C00004 h "$bram_addr" >> "$filename"
    devmem2 0x43C00000 h 0x0001 >> "$filename"
    echo "Readback" >> "$filename"
    bram_dout="$(devmem2 0x43C00008 | sed 's/ //g' | awk -F':' '{ print $2 }')"
    echo -e "\e[32mAddress="$bram_addr", Data="$bram_dout"\e[0m" >> "$filename"
    echo "$bram_dout"
}

devmem2_write_bits(){
    local bram_addr=$1
    local mask=$2
    local bram_data=$3

    init_channel >> "$filename"
    echo -e "\e[34mModifying BRAM: Address="$bram_addr", Mask="$mask", Value="$bram_data"\e[0m" >> "$filename"

    # Read the current value using devmem2_read
    bram_dout=$(devmem2_read "$bram_addr")
       
    # Apply bit mask to modify only selected bits
    new_value=$(( (bram_dout & ~mask) | (bram_data & mask) ))
    new_value=$(echo "obase=16; ibase=10; $new_value" | bc )

    echo "New Data to write=$new_value" >> "$filename"

    devmem2_write "$bram_addr" "0x$new_value"
}   

dac2_sweep_enable()
{
    echo "Enabling DAC2 Sweep..."
    devmem2_write 0x02c1 0x0001
    echo "Sweep Enabled."
}

sweep_20bit() {

    init_channel
    
    echo "Starting Sweep-20bit..."
    devmem2 0x43C00002 h 0x0100
    devmem2 0x43C00004 h 0x02c1
    devmem2 0x43C00006 h 0x0001
    devmem2 0x43C00000 h 0x0001
 
    init_channel
 
    echo "Sweep Enabled."
    devmem2 0x43C00002 h 0x0000
    devmem2 0x43C00004 h 0x02c1
    devmem2 0x43C00000 h 0x0001
    echo "Readback"
    devmem2 0x43C00008 h

}
 
export -f init_channel

export -f dac2_sweep_enable

export -f devmem2_write 

export -f devmem2_read

export -f sweep_20bit
