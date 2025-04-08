#!/bin/bash

# This script checks if the Temperature Control UART Receriver FIFO is empty,
# and if its not it reads all the bytes out and displays them on the console (as ASCII text)

read_reg() {
    register=$1
    devmem2 $register | awk -F': ' '{print $2}'
}

# Retreive the base address from the device tree:
TEMP_CTRL_BASE_ADDR=$(get_dt_addr temp_controller)

# Read status register at offset 0x8 and extract bit 2 (FIFO_empty)
status_reg=$(read_reg $(( TEMP_CTRL_BASE_ADDR + 0x8 )) )
FIFO_empty=$(( ( status_reg >> 2 ) & 0x1 ))

if [[ $FIFO_empty -ne 0 ]]; then
    echo "UART Receiver FIFO is empty"
else

    reg_val=$(read_reg $(( TEMP_CTRL_BASE_ADDR + 0x4 )) )
    FIFO_fill_level=$(( (reg_val >> 16) & 0xFFFF ))
    read_byte=$(( reg_val & 0xFF ))

    for (( i=0; 0 < FIFO_fill_level; i++ )); do
        printf "%X" $((read_byte)) | xxd -r -p
        reg_val=$(read_reg $(( TEMP_CTRL_BASE_ADDR + 0x4 )) )
        FIFO_fill_level=$(( (reg_val >> 16) & 0xFFFF ))
        read_byte=$(( reg_val & 0xFF ))
    done

    printf "\n"
fi

