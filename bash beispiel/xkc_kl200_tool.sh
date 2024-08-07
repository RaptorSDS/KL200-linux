#!/bin/bash

# XKC_KL200 Tool for Linux

PORT="/dev/ttyUSB0"
BAUDRATE="9600"

function send_command() {
    local command=$1
    echo -ne $command > $PORT
}

function calculate_checksum() {
    local data=$1
    local length=$2
    local checksum=0
    for (( i=0; i<length; i++ )); do
        checksum=$((checksum ^ $(printf "%d" "'${data:$i:1}")))
    done
    printf "\\x$(printf '%x' $checksum)"
}

function initialize_sensor() {
    stty -F $PORT $BAUDRATE cs8 -cstopb -parenb
}

function set_upload_mode() {
    local mode=$1
    local command="\x62\x34\x09\xFF\xFF$(printf '\\x%02x' $mode)\x00\x00"
    local checksum=$(calculate_checksum "$command" 8)
    send_command "$command$checksum"
}

function set_upload_interval() {
    local interval=$1
    if [ $interval -lt 1 ] || [ $interval -gt 100 ]; then
        echo "Invalid interval value. Must be between 1 and 100."
        return
    fi
    local command="\x62\x35\x09\xFF\xFF$(printf '\\x%02x' $interval)\x00\x00"
    local checksum=$(calculate_checksum "$command" 8)
    send_command "$command$checksum"
}

function set_led_mode() {
    local mode=$1
    if [ $mode -gt 3 ]; then
        echo "Invalid LED mode. Must be between 0 and 3."
        return
    fi
    local command="\x62\x37\x09\xFF\xFF$(printf '\\x%02x' $mode)\x00\x00"
    local checksum=$(calculate_checksum "$command" 8)
    send_command "$command$checksum"
}

function set_communication_mode() {
    local mode=$1
    if [ $mode -gt 1 ]; then
        echo "Invalid communication mode. Must be 0 (UART) or 1 (Relay)."
        return
    fi
    local command="\x62\x31\x09\xFF\xFF$(printf '\\x%02x' $mode)\x00\x00"
    local checksum=$(calculate_checksum "$command" 8)
    send_command "$command$checksum"
}

function read_distance() {
    local command="\x62\x33\x09\xFF\xFF\x00\x00\x00\x00"
    local checksum=$(calculate_checksum "$command" 8)
    send_command "$command$checksum"
    read -r -n 9 response < $PORT
    local raw_distance=$(printf '%d' "'${response:5:1}")$(printf '%d' "'${response:6:1}")
    echo "Distance: $raw_distance mm"
}

function show_menu() {
    while true; do
        echo "1. Set Upload Mode"
        echo "2. Set Upload Interval"
        echo "3. Set LED Mode"
        echo "4. Set Communication Mode"
        echo "5. Read Distance"
        echo "6. Exit"
        read -p "Select an option: " option

        case $option in
            1)
                read -p "Enter upload mode (0 for manual, 1 for auto): " mode
                set_upload_mode $mode
                ;;
            2)
                read -p "Enter upload interval (1-100): " interval
                set_upload_interval $interval
                ;;
            3)
                read -p "Enter LED mode (0-3): " mode
                set_led_mode $mode
                ;;
            4)
                read -p "Enter communication mode (0 for UART, 1 for Relay): " mode
                set_communication_mode $mode
                ;;
            5)
                read_distance
                ;;
            6)
                break
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

initialize_sensor
show_menu
