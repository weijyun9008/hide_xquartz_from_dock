#!/bin/bash

# Check if script is executable and make it executable if needed
if [[ ! -x "$0" ]]; then
  echo "Making script executable..."
  echo
  chmod +x "$0"
fi

# Show initial guidance
echo "Hide XQuartz From Dock"
echo "=============================="
echo

# Path to the application's Info.plist file
APP_PATH="/Applications/Utilities/XQuartz.app"
PLIST_PATH="$APP_PATH/Contents/Info.plist"

select_mode() {
  while true; do
    echo "Please select an option:"
    echo "1) Hide XQuartz from dock"
    echo "2) Show XQuartz in dock again"
    echo "3) Exit"
    echo
    read -p "Enter your choice (1-3): " choice
    echo
    
    case "$choice" in
      1) MODE="patch"; break ;;
      2) MODE="restore"; break ;;
      3) exit 0 ;;
      *) echo "Invalid option. Please try again." ;;
    esac
    echo
  done
}

# Function to restore from backup
restore_backup() {
  local backup_path="$1"
  echo "Restoring from backup: $backup_path"

  sudo cp "$backup_path" "$PLIST_PATH"
  sudo codesign --force --sign - "$APP_PATH"
  chmod 644 "$PLIST_PATH"
  chown $(whoami):admin "$PLIST_PATH"
  
  echo
  echo "Restore completed"
}

# Handle script interruption
trap 'echo "Script interrupted. Running cleanup..."; exit 1' INT TERM

# Show menu and get selection
select_mode

# Validate Info.plist existence before proceeding
if [[ ! -f "$PLIST_PATH" ]]; then
  echo "Error: $PLIST_PATH not found."
  exit 1
fi

# Quit the application before making changes
if [ "$MODE" == "patch" ] || [ "$MODE" == "restore" ]; then
  APP_NAME=$(basename "$APP_PATH" .app)
  osascript -e "quit app \"$APP_NAME\"" || {
    echo "Failed to quit $APP_NAME"
    exit 1
  }
fi

# Mode: Restore
if [ "$MODE" == "restore" ]; then
  # Use the backup file
  BACKUP_PATH="$APP_PATH/Contents/Info.plist.bak"
  if [ ! -f "$BACKUP_PATH" ]; then
    echo "Backup file not found"
    exit 1
  fi
  restore_backup "$BACKUP_PATH"
  exit 0
fi

# Mode: Patch
# Check if LSUIElement key already exists
if /usr/libexec/PlistBuddy -c "Print :LSUIElement" "$PLIST_PATH" &>/dev/null; then
  echo "LSUIElement key already exists in $PLIST_PATH."
  exit 1
fi

# Create backup with timestamp
BACKUP_PATH="$APP_PATH/Contents/Info.plist.bak"
if sudo cp "$PLIST_PATH" "$BACKUP_PATH"; then
  sudo chmod 644 "$BACKUP_PATH"
  sudo chown $(whoami):admin "$BACKUP_PATH"
  echo "Created backup at $BACKUP_PATH"
else
  echo "Failed to create backup"
  exit 1
fi

# Add LSUIElement key
if ! /usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$PLIST_PATH"; then
  echo "Failed to add LSUIElement key. Would you like to restore from backup? (y/n)"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    restore_backup "$BACKUP_PATH"
    exit 1
  fi
  exit 1
fi

# Re-sign the application after modification
sudo codesign --force --sign - "$APP_PATH"

# Set the appropriate permissions
chmod 644 "$PLIST_PATH"
chown $(whoami):admin "$PLIST_PATH"

# Confirm changes
if [[ $? -eq 0 ]]; then
  echo
  echo "XQuartz will no longer appear in the dock."
else
  echo
  echo "Failed to add LSUIElement key to $PLIST_PATH."
  exit 1
fi