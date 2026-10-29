#!/bin/bash

LOCAL_METADATA="${XDG_DATA_HOME:-$HOME/.local/share}/cinnamon/applets/Cinnamenu@json/metadata.json"
GITHUB_METADATA="https://raw.githubusercontent.com/fredcw/Cinnamenu/refs/heads/main/Cinnamenu%40json/metadata.json"
DOWNLOAD_URL="https://github.com/fredcw/Cinnamenu/archive/refs/heads/main.zip"
TEMP_DIR="/tmp/cinnamenu_update"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cinnamon/applets/Cinnamenu@json"

# Extract version number from metadata.json
extract_version() {
    grep -oP '"version":\s*"\K[^"]+' "$1"
}

version_compare() {
    local IFS=.
    local i v1=($1) v2=($2)

    for ((i=${#v1[@]}; i<${#v2[@]}; i++)); do v1[i]=0; done
    for ((i=${#v2[@]}; i<${#v1[@]}; i++)); do v2[i]=0; done

    for ((i=0; i<${#v1[@]}; i++)); do
        if ((10#${v1[i]} < 10#${v2[i]})); then
            return 1
        elif ((10#${v1[i]} > 10#${v2[i]})); then
            return 2
        fi
    done
    return 0
}

if [[ "$DESKTOP_SESSION" != cinnamon && "$DESKTOP_SESSION" != cinnamon-wayland ]]; then
  echo "Cinnamon is not the current desktop. Quitting..."
  exit 1
fi

echo "Cinnamenu installation/update script:"

# Fetch remote metadata.json
REMOTE_METADATA=$(mktemp)
curl -s "$GITHUB_METADATA" -o "$REMOTE_METADATA"
REMOTE_VERSION=$(extract_version "$REMOTE_METADATA")
echo "Remote version: $REMOTE_VERSION"

if [[ -f "$LOCAL_METADATA" ]]; then
    LOCAL_VERSION=$(extract_version "$LOCAL_METADATA")
    echo "Local version: $LOCAL_VERSION"
    version_compare "$REMOTE_VERSION" "$LOCAL_VERSION"
    case $? in
        0|1)
            echo "Remote version is older or the same."
            rm "$REMOTE_METADATA"
            exit 0
            ;;
    esac
    echo "Updating Cinnamenu."
else
	echo "Installing Cinnamenu. Don't forget to add Cinnamenu applet to your panel (System settings > Applets)"
fi

# Create temp directory
if [[ -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
fi
mkdir -p "$TEMP_DIR"

# Download the ZIP file
echo "Downloading..."
wget -q "$DOWNLOAD_URL" -O "$TEMP_DIR/cinnamenu.zip"
unzip -q "$TEMP_DIR/cinnamenu.zip" -d "$TEMP_DIR"

# Copy the files
echo "Installing..."
rm -rf "$TARGET_DIR"
mv "$TEMP_DIR/Cinnamenu-main/Cinnamenu@json" "$TARGET_DIR"

# Cleanup
rm -rf "$TEMP_DIR" "$REMOTE_METADATA"

# Reload applet
dbus-send --session --dest=org.Cinnamon.LookingGlass --type=method_call /org/Cinnamon/LookingGlass org.Cinnamon.LookingGlass.ReloadExtension string:Cinnamenu@json string:'APPLET'

echo "Finished!"
