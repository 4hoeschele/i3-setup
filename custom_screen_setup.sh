#!/bin/bash

# Define the laptop screen (update according to your setup)
LAPTOP_SCREEN="eDP"

# Terminate any running xrandr configurations (if necessary)
# (Not needed to kill Polybar as it won't be used)

# Wait until processes have been shut down (if any were running)
# (Not necessary if no termination commands are present)

# Function to get the lid status
get_lid_status() {
  grep -i "open" /proc/acpi/button/lid/LID/state >/dev/null && echo "open" || echo "closed"
}

# Move all workspaces to the primary monitor
move_workspaces() {
  primary_monitor=$1
  # Get a list of all workspaces
  workspaces=$(i3-msg -t get_workspaces | jq -r '.[].name')
  for ws in $workspaces; do
    i3-msg workspace "$ws"
    i3-msg move workspace to output "$primary_monitor"
  done
}

# Get the lid status
LID_STATUS=$(get_lid_status)

# Log the lid status for debugging
echo "Lid status: $LID_STATUS"

# Handle screen configuration dynamically
if type "xrandr"; then
  # Detect external monitors dynamically
  external_monitors=$(xrandr --query | grep " connected" | grep -v "$LAPTOP_SCREEN" | cut -d" " -f1)

  # Log detected external monitors for debugging
  echo "External monitors: $external_monitors"

  if [[ "$LID_STATUS" == "closed" ]] && [ -n "$external_monitors" ]; then
    # If the lid is closed and external monitors are connected
    primary_monitor=$(echo "$external_monitors" | head -n 1)
    xrandr --output "$primary_monitor" --primary --auto --output "$LAPTOP_SCREEN" --off
    move_workspaces "$primary_monitor"
    echo "Disabling laptop screen ($LAPTOP_SCREEN) and setting $primary_monitor as primary"
  else
    # If the lid is open or no external monitors are connected
    if [ -n "$external_monitors" ]; then
      primary_monitor=$(echo "$external_monitors" | head -n 1)
      xrandr --output "$primary_monitor" --primary --auto --right-of "$LAPTOP_SCREEN" --output "$LAPTOP_SCREEN" --auto
      move_workspaces "$primary_monitor"
      echo "Enabling laptop screen ($LAPTOP_SCREEN) with $primary_monitor as primary and extending to the right"
    else
      # No external monitors, enable the laptop screen
      xrandr --output "$LAPTOP_SCREEN" --auto --primary
      move_workspaces "$LAPTOP_SCREEN"
      echo "Enabling laptop screen ($LAPTOP_SCREEN) as primary"
    fi
  fi
else
  echo "xrandr not available, unable to configure monitors dynamically"
fi
