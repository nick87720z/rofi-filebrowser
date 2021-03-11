Minimal file browser script for rofi.

## Usage

$ rofi -show files -modi files:rofi-filebrowser.sh

## Environment variables:
ROFI_FB_USE_ICONS=1 to enable icons support.
ROFI_FB_COLORS=1 to enable ls-style colorization.

## Dependencies:

- bash
- coreutils
- sed
- xdg-utils

### Optional (for icons support):

- file
- File-MimeInfo
