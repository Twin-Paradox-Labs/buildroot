#!/bin/bash

# This script takes the Temperature Contoller UART command as a string and puts the ASCII code into the UART transmitter register in the FPGA
# Commands must start with a < bracket and end with a > bracket - refer to Osidian Vault note for more info on command structure

if [ $# -eq 0 ]; then
    echo
    echo "Usage: $0 \"<command_string>\""
    echo "The command must be in double quotation marks otherwise the '<' bracket will be interpreted by the shell as an input redirection"
    echo
    echo "Example usage: "
    echo "temp_ctrl_cmd.sh \"<Lc,100>\""
    echo
    exit 1
fi
cmd_string="$1"

read_reg() {
    register=$1
    devmem2 $register | awk -F': ' '{print $2}'
}

# Retreive the base address from the device tree:
TEMP_CTRL_BASE_ADDR=$(get_dt_addr temp_controller)

# This loop parses through the input string and converts to ASCII code
# then writes the ASCII code into the transmitter register of the UART
for (( i=0; i<${#cmd_string}; i++ )); do
    char="${cmd_string:$i:1}"
    ascii_code=$(printf "0x%02X" "'$char")
    echo "Sending byte: 0x$ascii_code"

    devmem2 $TEMP_CTRL_BASE_ADDR w $ascii_code
    uart_ready=$(read_reg $(( $TEMP_CTRL_BASE_ADDR + 0x8 ))) # offset 0x8 is the uart status register

    # Wait for the UART 'ready' status to go high, indicating its finished with the current byte and ready for the next one:
    while [[ $uart_ready -ne 0x1 ]]; do
        echo "Waiting for UART to finish current byte. Status = $uart_ready"
        sleep 0.0001
        uart_ready=$(read_reg $(( $TEMP_CTRL_BASE_ADDR + 0x8 )))
    done

done


