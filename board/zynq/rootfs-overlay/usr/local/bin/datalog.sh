#!/bin/bash

# Usage message
usage() {
    echo "Usage: $0 {start|stop}"
    exit 1
}

# Check if exactly one argument is passed
if [ "$#" -ne 1 ]; then
    usage
fi

# Handle start/stop commands
case "$1" in
    start)
        echo "start" | tee /sys/kernel/data_logger/enable
        ;;
    stop)
        echo "stop" | tee /sys/kernel/data_logger/enable
        ;;
    *)
        usage
        ;;
esac