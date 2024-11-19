#!/bin/bash

# Colors - using bright red background and bright white text
RED='\033[1;97;101m' # Bright red background with bright white text
NC='\033[0m'         # No Color

# Generate a more aggressive mono beep file
# Higher frequency (2500Hz), longer duration, louder volume, added overdrive
# sox -n -r 44100 -c 1 -b 16 /tmp/sync_beep.wav \
#   synth 0.08 sine 2500 \
#   gain -3 \
#   overdrive 40 20

# Clear screen and hide cursor
clear
tput civis

# Function to restore terminal on exit
cleanup() {
  tput cnorm # Restore cursor
  echo -e "\n${NC}Exiting..."
  exit 0
}
trap cleanup INT

echo "Press Enter repeatedly to generate sync beeps (Ctrl+C to exit)"
echo

# Function to show big flash
show_flash() {
  echo -e "\n\n"
  echo -e "${RED}    ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄    ${NC}"
  echo -e "${RED}    ████████╗ ██████╗ ██╗    ██╗██╗██╗    ${NC}"
  echo -e "${RED}    ╚══██╔══╝██╔═══██╗██║    ██║██║██║    ${NC}"
  echo -e "${RED}       ██║   ██║   ██║██║ █╗ ██║██║██║    ${NC}"
  echo -e "${RED}       ██║   ██║   ██║██║███╗██║╚═╝╚═╝    ${NC}"
  echo -e "${RED}       ██║   ╚██████╔╝╚███╔███╔╝██╗██╗    ${NC}"
  echo -e "${RED}       ╚═╝    ╚═════╝  ╚══╝╚══╝ ╚═╝╚═╝    ${NC}"
  echo -e "${RED}    ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀    ${NC}"
  echo -e "\n\n"
}

# Function to clear flash
clear_flash() {
  echo -en "\033[11A" # Move up 11 lines
  for i in {1..11}; do
    echo -e "\r\033[K" # Clear each line
  done
  echo -en "\033[11A" # Move back up
}

while true; do
  read -r
  show_flash
  aplay -q sync_beep.wav
  clear_flash
done
