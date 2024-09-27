#!/bin/bash

# Capture the list of variables before the script runs
declare -g EXTERNAL_VARIABLES=($(compgen -v))

#declare -g -a INSTALLATION_FILES=()

declare -g FLAG_REMOVE_INSTALATION_FILES=false
declare -g FLAG_REBOOT_UPON_COMPLETION=false
declare -g LOG_LEVEL=1

# Set the log file to be used.
declare -g LOG_PATH=/userdata/system/logs
declare -g LOG_FILE="${LOG_PATH}/remote_installer.log"
[ ! -z "$0" ] && [[ "$0" != "bash" ]] && LOG_FILE="${LOG_PATH}/$(basename -- "$0" | sed 's/\.[^.]*$//').log"

###############################################
##                                           ##
## debug_list_variables                      ##
## This function prints any variables set to ##
## this point in the script.  This function  ##
## can be removed if not needed              ##
##                                           ##
###############################################
debug_list_variables() {
    function is_external_variable() {
        local variable_name=$1
        for external_variable in "${EXTERNAL_VARIABLES[@]}"; do
            if [[ "$external_variable" == "$variable_name" ]]; then
                return 0
            fi
        done
        return 1
    }

    echo "========================" | tee >&2 -a "$LOG_FILE"
    echo "DEBUG: $(date)" | tee >&2 -a "$LOG_FILE"

    if [ $# -gt 0 ]; then
        echo "DEBUG: Variables passed into the script:" | tee >&2 -a "$LOG_FILE"
        for ((i=0; i<=$#; i++)); do
            echo "    \$$i = ${!i}" | tee >&2 -a "$LOG_FILE"
        done
    else
        echo "DEBUG: Script: $0" | tee >&2 -a "$LOG_FILE"
    fi
    echo "DEBUG: Working Directory: $PWD" | tee >&2 -a "$LOG_FILE"

    # Compare the initial and final sets to find new variables
    echo "BEBUG: Variables set within this script:" | tee >&2 -a "$LOG_FILE"
    [ ! -v EXTERNAL_VARIABLES ] && echo "WARNING: EXTERNAL_VARIABLES not set.  All variables will be shown." | tee >&2 -a "$LOG_FILE"
    local current_variables=($(compgen -v))
    for variable_name in "${current_variables[@]}"; do
        if ! is_external_variable "$variable_name" && [ "$variable_name" != "EXTERNAL_VARIABLES" ]; then
            local var_info="$(declare -p "$variable_name" 2>/dev/null)"
            [ ! -z "$var_info" ] && echo "    $var_info" | tee >&2 -a "$LOG_FILE"
        fi
    done
}

function list_github_files() {
    local repo="$1"
    local path="$2"
    local branch="${3:-main}"  # Optional third argument for branch, defaulting to 'main'
    
    # Get the repo owner and name from the 'repo' variable
    local owner=$(echo "$repo" | cut -d'/' -f1)
    local repo_name=$(echo "$repo" | cut -d'/' -f2)
    
    # Step 1: Get the commit SHA for the branch
    local commit_sha=$(curl -sL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/$repo/branches/$branch \
        | jq -r '.commit.sha')

    # Step 2: Get the tree using the commit SHA
    local tree_url="https://api.github.com/repos/$repo/git/trees/$commit_sha?recursive=1"
    curl -sL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$tree_url" \
        | jq -r --arg base_path "$path" --arg owner "$owner" --arg repo_name "$repo_name" --arg branch "$branch" \
        '.tree[] 
            | select(.path | startswith($base_path)) 
            | if .type == "blob" then 
                "https://raw.githubusercontent.com/\($owner)/\($repo_name)/\($branch)/\(.path) \(.path) \(.mode | contains("100755") | if . then "true" else "false" end)" 
            else 
                empty 
            end'
}

function download_github_files() {
    local repo="$1"
    local path="$2"
    local destination_path="$3"
    local ignore="$4"  # Optional ignore patterns (supports ! modifier)

    # Create destination directory if it doesn't exist
    mkdir -p "$destination_path"

    # Get the list of files from the GitHub repo
    local file_list=$(list_github_files "$repo" "$path")

    [ $LOG_LEVEL -gt 1 ] && echo "DEBUG: Listing files to download..." | tee >&2 -a "$LOG_FILE"
    [ $LOG_LEVEL -gt 1 ] && echo "$file_list" | tee >&2 -a "$LOG_FILE"

    # Separate ignore and re-include patterns
    local ignore_patterns=()
    local include_patterns=()

    # Split patterns by '|' and sort them into ignore and include arrays
    IFS='|' read -ra patterns <<< "$ignore"
    for pattern in "${patterns[@]}"; do
        if [[ "$pattern" == !* ]]; then
            include_patterns+=("${pattern:1}")  # Remove leading '!'
        else
            ignore_patterns+=("$pattern")
        fi
    done

    # Loop through each line of file_list
    while IFS= read -r line; do
        local url=$(echo "$line" | awk '{print $1}')
        local file_path=$(echo "$line" | awk '{print $2}')
        local executable=$(echo "$line" | awk '{print $3}')

        local ignore_file=false
        local include_file=false

        # Check if the file matches any ignore pattern
        for pattern in "${ignore_patterns[@]}"; do
            if echo "$file_path" | grep -E -q "$pattern"; then
                ignore_file=true
                break
            fi
        done

        # Check if the file matches any re-include pattern (with ! modifier)
        for pattern in "${include_patterns[@]}"; do
            if echo "$file_path" | grep -E -q "$pattern"; then
                include_file=true
                break
            fi
        done

        # Skip the file if it's ignored and not re-included
        if [[ "$ignore_file" == true && "$include_file" == false ]]; then
            [ $LOG_LEVEL -gt 1 ] && echo "DEBUG: Skipping ignored file: $file_path" | tee >&2 -a "$LOG_FILE"
            continue
        fi

        # Create the corresponding local directory structure
        local destination_file="$destination_path/$file_path"
        local destination_dir=$(dirname "$destination_file")

        mkdir -p "$destination_dir"

        # Download the file
        [ $LOG_LEVEL -gt 0 ] && echo "DEBUG: Downloading $file_path..." | tee >&2 -a "$LOG_FILE"
        curl -sL "$url" -o "$destination_file"

        # Make it executable if needed
        if [[ "$executable" == "true" ]]; then
            [ $LOG_LEVEL -gt 0 ] && echo "DEBUG: Making $file_path executable" | tee >&2 -a "$LOG_FILE"
            chmod +x "$destination_file"
        fi
    done <<< "$file_list"
}

###############################################
##                                           ##
## Cleanup the installation files            ##
## This section is optional but can delete   ##
## the installation scripts.                 ##
##                                           ##
###############################################
function cleanup()  {
    if [ $FLAG_REMOVE_INSTALATION_FILES = true ]; then
        [ $LOG_LEVEL -gt 0 ] && echo "DEBUG: Do cleanup" | tee >&2 -a "$LOG_FILE"
        if [ ! -z "$0" ] && [[ "$0" != "bash" ]]; then
            [ $LOG_LEVEL -gt 1 ] && echo "DEBUG: Removing file \"$0\"" | tee >&2 -a "$LOG_FILE"
            rm -f "$0"
            [ $LOG_LEVEL -gt 1 ] && echo "DEBUG: Reload games list" | tee >&2 -a "$LOG_FILE"
            batocera-es-swissknife --restart &
        fi
    fi
}

#debug_list_variables "$@"
download_github_files \
    "zarquon-42/knulli-bootlogos" \
    "" \
    "/userdata/system/patches" \
    "install.sh|.gitignore|.*\.md|.*\.txt|.*\.log|bootlogo/.*.bmp|!info.txt" >/dev/null

cleanup "$@"

if [ $FLAG_REMOVE_INSTALATION_FILES = true ]; then
    [ $LOG_LEVEL -gt 0 ] && echo "DEBUG: reboot" | tee >&2 -a "$LOG_FILE"
    reboot
    exit 0
fi
