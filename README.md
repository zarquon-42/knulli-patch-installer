# knulli-patch-installer

This repo is where I am currently testing ways to easily
deploy patches in knulli.

## Setup Instructions

This is in Alpha but if you wish to test simply copy the
Patch-Installer.pygame file to you roms/pygame folder and
run it from within Knulli after updating the Games List.

The first time you run the app it will will ask you to
download some patch definition files.  If you do not wish
to do this and have your own patch files, you can place
them in a /userdata/system/patches folder.

## Usage

When in the app the following key presses are used:

- D-Pad Up and Down to either scroll or select.
- D-Pad Right to move to the description for scrolling if needed.
- D-Pad Left to navigate the patch list and select.
- A Button to select.
- B Button to exit
- Y Button to re-download/load the patch list

In addition there are some advance functions for helping
in development:

- X Button to turn on debugging logging
- Select Button to Toggle Dry-Run mode.

## CLI Usage

This can also be used as a CLI by making the file executable
with `chmod +x /userdata/roms/pygame/Patch_installer.pygame`
then run it from with `/userdata/roms/pygame/Patch_installer.pygame --help`
to get usage information.
