# knulli-patch-installer

This repo is where I am currently testing ways to easily
deploy patches in knulli.

## Setup Instructions

This is in Alpha but if you wish to test simply copy the
`Patch-Installer.pygame` file to you `roms/pygame` folder
and run it from within the pygame section of Knulli after
updating the Games List.

Alternatively, you could `SSH` into the device and then
enter the commands:

```bash
cd /userdata/roms/pygame
wget https://raw.githubusercontent.com/zarquon-42/knulli-patch-installer/refs/heads/main/Patch-Installer.pygame

```

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

This can also be used as a CLI by making the file executable with:

```bash
chmod +x /userdata/roms/pygame/Patch_installer.pygame
```

Then run it from with:

```bash
/userdata/roms/pygame/Patch_installer.pygame --help
```

This will display usage:

```sh
usage: Patch-Installer.pygame [-h] [--patch-id PATCH_ID] [--dry-run] [-q] [-v] [--log-file LOG_FILE] [<Patch File>]

Patch Installer Tool

positional arguments:
  <Patch File>         Path to the patch YAML or JSON file.

options:
  -h, --help           show this help message and exit
  --patch-id PATCH_ID  Specify the patch ID if the file contains more than one patch.
  --dry-run            Perform a dry run without actually applying the patch.
  -q, --quiet          Decrease logging verbosity. Can be used multiple times.
  -v, --verbose        Increase logging verbosity. Can be used multiple times.
  --log-file LOG_FILE  Specify the log file. Default: /userdata/system/logs/patch-installer.log
```
