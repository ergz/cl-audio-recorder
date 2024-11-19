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

# Check if sox is installed
check_sox() {
  if ! command -v sox &>/dev/null; then
    echo -e "${YELLOW}sox is not installed. Install it for audio processing:${NC}"
    echo -e "${GREEN}sudo apt-get install sox${NC}"
    return 1
  fi
  return 0
}

# Check if filename base is provided
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: No filename provided${NC}"
  echo -e "Usage: $0 ${YELLOW}filename${NC}"
  echo -e "Example: $0 ${YELLOW}interview${NC}"
  exit 1
fi

# Create filename with timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")
filename="${1}_${timestamp}.wav"
raw_filename="raw_${filename}"

# Main script
print_header
list_mics

# Get card number
echo -ne "${BOLD}Enter card number from above:${NC} "
read card_number

# Usually device number is 0
device_number=0
echo -e "${GREEN}Using default device number: 0${NC}"

# Format the device string
device="hw:$card_number,$device_number"

# Test device before recording
if ! arecord -D "$device" -d 1 -f S24_3LE /dev/null >/dev/null 2>&1; then
  echo -e "${RED}Error: Could not open device $device${NC}"
  exit 1
fi

# Audio processing options
echo
echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       ${BOLD}Audio Processing Setup${NC}${BLUE}      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
echo

if check_sox; then
  echo -ne "${BOLD}Enable noise gate? (y/n):${NC} "
  read use_noise_gate

  echo -ne "${BOLD}Enable compression? (y/n):${NC} "
  read use_compression

  echo -ne "${BOLD}Enable normalization? (y/n):${NC} "
  read use_normalization

  # Build sox command
  sox_command="sox $raw_filename $filename"
  if [ "$use_noise_gate" = "y" ]; then
    sox_command="$sox_command noisered"
  fi
  if [ "$use_compression" = "y" ]; then
    sox_command="$sox_command compand 0.3,1 6:-70,-60,-20 -5 -90 0.2"
  fi
  if [ "$use_normalization" = "y" ]; then
    sox_command="$sox_command norm"
  fi
else
  echo -e "${YELLOW}No audio processing available (sox not installed)${NC}"
  raw_filename="$filename"
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
echo -e "${BOLD}Output:${NC} $filename"
if [ "$raw_filename" != "$filename" ]; then
  echo -e "${BOLD}Processing:${NC} Yes"
  if [ "$use_noise_gate" = "y" ]; then echo -e " - Noise Gate"; fi
  if [ "$use_compression" = "y" ]; then echo -e " - Compression"; fi
  if [ "$use_normalization" = "y" ]; then echo -e " - Normalization"; fi
fi
echo

# Start recording in background
echo -e "${GREEN}Starting recording...${NC}"
arecord -D "$device" -f S24_3LE -r 48000 -t wav "$raw_filename" &>/dev/null &
record_pid=$!

# Show recording animation
show_recording_animation $record_pid

# This line will only be reached after Ctrl+C is pressed
echo -e "\n\n${GREEN}Recording stopped.${NC}"

# Apply audio processing if enabled
if [ "$raw_filename" != "$filename" ]; then
  echo -e "${GREEN}Applying audio processing...${NC}"
  eval $sox_command
  rm "$raw_filename"
  echo -e "${GREEN}Processing complete.${NC}"
fi

echo -e "${GREEN}Recording saved to: $filename${NC}"
