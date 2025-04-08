#!/bin/bash

PID_FILE="/tmp/temp_ctrl_telem_log.pid"
LOG_FILE="/home/laser/temp_ctrl_telem.log"
POLL_INTERVAL_MS="$2"

start() {
    if [[ -z "$POLL_INTERVAL_MS" ]]; then
        echo "Polling interval (ms) not specified."
        echo "Usage: $0 start <interval_ms>"
        exit 1
    fi

    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "temp_ctrl_telem_log is already running with PID $(cat $PID_FILE)"
    else
        nohup temp_ctrl_telem_log "$POLL_INTERVAL_MS" >> "$LOG_FILE" 2>/dev/tty &
        echo $! > "$PID_FILE"
        echo "Started temp_ctrl_telem_log with PID $(cat $PID_FILE) and interval ${POLL_INTERVAL_MS} ms"
    fi
}

stop() {
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        kill $(cat "$PID_FILE")
        rm -f "$PID_FILE"
        echo "Stopped temp_ctrl_telem_log"
    else
        echo "temp_ctrl_telem_log is not running"
    fi
}

status() {
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "temp_ctrl_telem_log is running with PID $(cat $PID_FILE)"
    else
        echo "temp_ctrl_telem_log is not running"
    fi
}

case "$1" in
    start)   start ;;
    stop)    stop ;;
    status)  status ;;
    restart) stop; sleep 1; start ;;
    *)
        echo "Usage: $0 {start <interval_ms>|stop|status <interval_ms>}"
        ;;
esac