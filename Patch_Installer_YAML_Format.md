# Patch Installer YAML Format

This document describes the structure of the YAML files used to define patches in the Patch Installer application.

Each YAML file can contain one or more patch definitions. Each patch consists of metadata such as a title, description, and installation instructions. The patches may include optional information about board compatibility and file extraction steps.

## Basic Structure

The YAML file starts with a list of patches. Each patch can contain two groups of keys.  These can be broken down to

1. Keys defining and describing the patch.
2. Keys describing the actions and tasks to take to install the patch.

### Patch Definition and Description

- **title**: (Required) A human-readable title for the patch.
- **description**: (Optional) A detailed explanation of what the patch does.
- **patch_id**: A unique identifier for the patch. Required only if more than one patch exists in the YAML file.
- **boards**: (Optional) A list of specific boards or regex patterns to define which hardware the patch is compatible with. Boards can be listed explicitly, or regex patterns can be used to match multiple boards. Each entry can be:
  - A specific board (e.g., `rg40xx`).
  - A regular expression (e.g., `^rg.*xx.*`) to match multiple boards.

### Actions and Tasks

- **tasks**: (Required) The root key containing a list of actions to be taken.
  - **files**: This could be a local path or a URL.  A common use case would be to download script files, zip files, images or other files from the internet.  You can also download repositories or part of a repository from github.
    - **source**: Path of source file or directory.  This can also be a URL.  The URL can be to a specific file or to a complete repo.
    - **destination**: Where to place the file.
    - **github_path**: (Optional and only relevant with github repositories) Path to the part of the github repo to download.
    - **ignore**: (Optional and only relevant with github repositories) A pipe separated list regex expressions describing files to ignore (or include using the "!" modifier.)
    - **executable**: A boolean value indicating whether the file should be marked executable (for scripts or binaries).
  - **extract**: This section contains details about how
  to extract the patch files.
    - **source**: Path of the Zip file to extract.
    - **destination**: Where to extract it.
  - **executable**: Mark files as executable.
    - **path**: Path to the file to be marked as executable.
  - **alert**: A message to display to the user
  - **commands**: A list of shell commands to run after the patch has been installed or extracted.


## YAML Example

Below is an example of a YAML file containing multiple patches:

```yaml
- title: "RG40XX H/V Joystick Fix by @Gamma"
  id: gamma_joystick_fix_g40xx-boot-modded
  description: >
    Please be aware that you could break your system if something
    goes wrong. Be careful and mind the risk of having to start over
    with your Knulli setup before you proceed.  You could also just
    wait for the next Knulli release which will most likely come
    with patch applied.

    For more info see: https://discord.com/channels/1173228527605272666/1261038054773227680/1283889420113678377

  boards: 
    - "rg40xx"

  tasks:
    - files:
      - source: "https://github.com/zarquon-42/knulli-patches/raw/refs/heads/main/patches/rg40xx-boot-modded.img"
        destination: "/tmp/patch/"
    
    - alert:
      - "About to overwrite the boot partition with rg40xx-boot-modded.img"

    - commands:
      - "dd if=/tmp/patch/rg40xx-boot-modded.img of=/dev/mmcblk0p1"

    - reboot

- title: "Bootlogo Changer App"
  id: bootlogo_changer_app_install_patch
  description: >
    This is a utility you can use to update your Knulli bootlogo's

    This contains some bootlogo images not created by me.  Some of
    the images were modified by me but the base image was created
    by others.

  tasks:
    - files:
      - source: "https://raw.githubusercontent.com/zarquon-42/knulli-bootlogos/refs/heads/main/Change-Bootlogo.pygame"
        destination: "/userdata/roms/pygame/change-bootlogo/"
        executable: true
      - source: "https://raw.githubusercontent.com/zarquon-42/knulli-bootlogos/refs/heads/main/change-bootlogo.sh"
        destination: "/opt/"
        executable: true

      - source: "https://github.com/zarquon-42/knulli-bootlogos"
        destination: "/userdata/system/patches"
        github_path: "bootlogo"
        ignore: ".*.md|install.sh|.gitignore|!important.md"

    - commands:
        - "mv /opt/change-bootlogo.sh /opt/change-bootlogo"
```

---

This format allows for the flexibility to support a variety of patches, ranging from simple script files to more complex multi-file patches that need to be extracted and installed on specific boards. Developers can create YAML files using this format to define patches for the application to process.
