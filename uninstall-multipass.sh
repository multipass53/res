#!/usr/bin/env zsh

setopt null_glob

# Check for TTY
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NO_COLOR='\033[0m'
    BOLD=$(tput bold)
else
    GREEN=""
    RED=""
    BLUE=""
    NO_COLOR=""
    BOLD=""
fi

function run {
    echo " $ ${GREEN}$@${NO_COLOR}"
    if [[ $dry_run == false ]]; then
        eval "$@"
        if [[ $? -ne 0 ]]; then
            echo "Something went wrong. Aborting."
            exit 1
        fi
    fi
}

function run_ignore_error {
    echo " $ ${GREEN}$@${NO_COLOR}"
    if [[ $dry_run == false ]]; then
        eval "$@"
    fi
}

function echobold {
    echo "${BOLD}$@${NO_COLOR}"
}

function uninstall_multipass {
    if [[ ! -f $multipass_path ]]; then
        echobold "Multipass is not installed. Nothing to uninstall."
        exit 0
    fi

    # Prompt for confirmation
    printf "Are you sure you want to uninstall Multipass? ${RED}(y/N)${NO_COLOR}: "
    read -r choice
    if [[ $choice != "y" ]]; then
        echobold "\nNothing done."
        exit 1
    fi

    echobold "\nStopping all instances..."
    command='multipass stop --all'
    run $command

    echobold "\nDeleting all instances..."
    command='multipass delete --all --purge'
    run $command

    echobold "\nRunning built-in uninstaller..."
    echo "You may need to type in your password..."
    command='sudo sh "/Library/Application Support/com.canonical.multipass/uninstall.sh"'
    run_ignore_error $command

    if [[ -f $multipass_path ]]; then
        echo "Something went wrong. Aborting."
        exit 0
    fi

    echobold "\nMultipass has been successfully uninstalled."
}

function cleanup {
    if [[ -f $multipass_path ]]; then
        echobold "Multipass is still installed. Cannot clean up yet."
        exit 0
    fi

    if [[ $1 == false ]]; then
        echo "Some leftover files ${BOLD}could be${NO_COLOR} present here:"
    else
        echo "\nSome leftover files remain:"
    fi

    delete_paths=(
        ~/Library/"Application Support"/multipass-*
        ~/Library/Preferences/multipass/
        ~/Library/Preferences/multipass.gui.plist
        ~/Library/Preferences/Multipass.plist
    )

    for target_path in "${delete_paths[@]}"; do
        echo " - ${BLUE}$target_path${NO_COLOR}"
    done

    printf "Would you like to clean those up too (OPTIONAL)? ${RED}(y/N)${NO_COLOR}: "
    read -r choice
    if [[ $choice != "y" ]]; then
        echobold "\nNo leftover cleanup done."
        echo "If you want to clean up those files later, run this script with the ${BLUE}--cleanup-only${NO_COLOR} flag."
        exit 0
    fi

    echobold "\nDeleting files..."
    for target_path in "${delete_paths[@]}"; do
        run_ignore_error "sudo rm -rfv \"$target_path\""
    done
    echobold "\nFinished uninstalling Multipass and removed leftover files."
}

multipass_path=$(command -v multipass)

# Checking arguments
if [[ $1 == "--dry-run" ]]; then
    dry_run=true
    echo "Dry run enabled. No changes will be made."
else
    dry_run=false
fi

if [[ $1 == "--cleanup-only" ]]; then
    cleanup false
    exit 0
fi

if [[ $1 == "--help" ]]; then
    echo "usage: sh uninstall-multipass.sh [--dry-run] [--cleanup-only]"
    exit 0
fi

uninstall_multipass
cleanup
