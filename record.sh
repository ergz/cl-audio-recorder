#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print colored header
print_header() {
  clear
  echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║     ${BOLD}Simple Audio Recorder${NC}${BLUE}         ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
  echo
}

# Function to list all recording devices
list_mics() {
  echo -e "${YELLOW}Available Recording Devices:${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  arecord -l | grep -E "^card [0-9]" | while read line; do
    card_num=$(echo $line | grep -o "card [0-9]" | cut -d' ' -f2)
    dev_num=$(echo $line | grep -o "device [0-9]" | cut -d' ' -f2)
    echo -e "${GREEN}▶ $line${NC}"
    echo -e "  ${BOLD}Use card number:${NC} ${YELLOW}$card_num${NC}"
    echo
  done
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Print recording animation
show_recording_animation() {
  local pid=$1
  local symbols=('⚫' '⚪')
  local delay=1

  while kill -0 $pid 2>/dev/null; do
    for symbol in "${symbols[@]}"; do
      echo -ne "\r${RED}$symbol ${BOLD}Recording...${NC} (Press ${YELLOW}Ctrl+C${NC} to stop) "
      sleep $delay
    done
  done
}

# Main script
print_header
list_mics

# Get card number
echo -ne "${BOLD}Enter card number from above:${NC} "
read card_number

# Usually device number is 0
device_number=0
echo -e "${GREEN}Using default device number: 0${NC}"

# Check if filename argument is provided
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: No output filename provided${NC}"
  echo -e "Usage: $0 ${YELLOW}output_filename.wav${NC}"
  exit 1
fi

# Format the device string
device="hw:$card_number,$device_number"

# Test device before recording
if ! arecord -D "$device" -d 1 -f S24_3LE /dev/null >/dev/null 2>&1; then
  echo -e "${RED}Error: Could not open device $device${NC}"
  exit 1
fi

# Start recording
echo
echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          ${BOLD}Recording Setup${NC}${BLUE}          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
echo
echo -e "${BOLD}Device:${NC} $device"
echo -e "${BOLD}Format:${NC} 24-bit (S24_3LE)"
echo -e "${BOLD}Sample Rate:${NC} 48kHz"
echo -e "${BOLD}Output:${NC} $1"
echo

# Start recording in background
echo -e "${GREEN}Starting recording...${NC}"
arecord -D "$device" -f S24_3LE -r 48000 -t wav "$1" &>/dev/null &
record_pid=$!

# Show recording animation
show_recording_animation $record_pid

# This line will only be reached after Ctrl+C is pressed
echo -e "\n\n${GREEN}Recording saved to: $1${NC}"
