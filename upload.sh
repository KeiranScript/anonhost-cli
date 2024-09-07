#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display a cute progress bar
progress_bar() {
  local width=40

  echo -ne "${YELLOW}Uploading: ${NC}"
  for ((i = 0; i < $width; i++)); do
    echo -ne "▱"
  done
  echo -ne "\r"
  echo -ne "${YELLOW}Uploading: ${NC}"

  for ((i = 0; i < $width; i++)); do
    sleep 0.1
    echo -ne "▰"
  done
  echo -ne "\n"
}

# Function to copy to clipboard
copy_to_clipboard() {
  local content="$1"

  if [ "$(uname)" == "Darwin" ]; then
    # macOS
    echo -n "$content" | pbcopy
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}URL copied to clipboard (pbcopy)${NC}"
    else
      echo -e "${RED}Failed to copy to clipboard (pbcopy)${NC}"
    fi
  elif [ -n "$WAYLAND_DISPLAY" ]; then
    # Wayland
    if command -v wl-copy >/dev/null 2>&1; then
      echo -n "$content" | wl-copy
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}URL copied to clipboard (wl-copy)${NC}"
      else
        echo -e "${RED}Failed to copy to clipboard (wl-copy)${NC}"
      fi
    else
      echo -e "${YELLOW}Clipboard utility wl-copy not found. Install wl-clipboard.${NC}"
    fi
  elif [ -n "$DISPLAY" ]; then
    # X11
    if command -v xclip >/dev/null 2>&1; then
      echo -n "$content" | xclip -selection clipboard
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}URL copied to clipboard (xclip)${NC}"
      else
        echo -e "${RED}Failed to copy to clipboard (xclip)${NC}"
      fi
    elif command -v xsel >/dev/null 2>&1; then
      echo -n "$content" | xsel --clipboard --input
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}URL copied to clipboard (xsel)${NC}"
      else
        echo -e "${RED}Failed to copy to clipboard (xsel)${NC}"
      fi
    else
      echo -e "${YELLOW}Clipboard utilities not found. Install xclip or xsel.${NC}"
    fi
  else
    echo -e "${YELLOW}Clipboard copy not available in this environment.${NC}"
  fi
}

# Check if a file is provided
if [ $# -eq 0 ]; then
  echo -e "${RED}Error: No file specified${NC}"
  echo "Usage: $0 <file_path>"
  exit 1
fi

file_path="$1"

# Check if the file exists
if [ ! -f "$file_path" ]; then
  echo -e "${RED}Error: File not found${NC}"
  exit 1
fi

# Display file info
file_size=$(du -h "$file_path" | cut -f1)
echo -e "${YELLOW}Uploading file:${NC} $file_path (${GREEN}$file_size${NC})"

# Start the progress bar in the background
progress_bar &
progress_pid=$!

# Upload the file
response=$(curl -s -X POST https://kuuichi.xyz/api/upload -F "file=@$file_path")

# Kill the progress bar
kill $progress_pid 2>/dev/null

# Extract the URL from the response
url=$(echo $response | grep -o 'https://[^"]*')

if [ -z "$url" ]; then
  echo -e "\n${RED}Error: Failed to upload file${NC}"
  echo "API Response: $response"
  exit 1
fi

# Print the result
echo -e "\n${GREEN}File uploaded successfully!${NC}"
echo -e "${YELLOW}URL:${NC} $url"

# Copy URL to clipboard
copy_to_clipboard "$url"
