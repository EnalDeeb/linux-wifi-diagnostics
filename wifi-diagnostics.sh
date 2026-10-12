#!/usr/bin/env bash
# Wi-Fi diagnostics for Debian 12/13 and Fedora.
# Installs missing diagnostic utilities on Debian; collection is read-only.
# Run as your normal user: bash wifi-diagnostics.sh

export LC_ALL=C
export PATH="$PATH:/usr/sbin:/sbin"
umask 077
LOG=$(mktemp "$HOME/lenovo-wifi-$(date +%Y%m%d-%H%M%S)-XXXXXX.txt") || exit 1

# Authenticate before redirecting output, so a password prompt remains visible.
JOURNAL_MODE=user
if (( EUID == 0 )); then
    JOURNAL_MODE=root
elif command -v sudo >/dev/null 2>&1; then
    printf 'Kernel log access may require your sudo password.\n'
    if sudo -v; then
        JOURNAL_MODE=sudo
    else
        printf 'Continuing with available unprivileged journal access.\n'
    fi
fi

install_dependencies() {
    local distro_id tool
    local -a missing=()
    INSTALL_STATUS='Automatic dependency installation skipped (not Debian).'
    distro_id=$( . /etc/os-release; printf '%s' "${ID:-}" )
    [[ $distro_id == debian ]] || return 0

    for tool in lspci ip iw rfkill lsmod; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done
    INSTALL_STATUS='All required diagnostic utilities already available.'
    (( ${#missing[@]} > 0 )) || return 0

    printf 'Missing diagnostic commands: %s\n' "${missing[*]}"
    printf 'Installing Debian packages: pciutils iproute2 iw rfkill kmod\n'
    printf 'APT may ask you to confirm installation. Internet access may be required.\n'
    INSTALL_STATUS='Dependency installation unavailable; collecting with existing tools.'
    if ! command -v apt >/dev/null 2>&1; then
        printf 'APT is unavailable. Continuing with existing tools.\n'
        return 0
    fi
    if [[ $JOURNAL_MODE == root ]]; then
        apt install pciutils iproute2 iw rfkill kmod
    elif [[ $JOURNAL_MODE == sudo ]]; then
        sudo apt install pciutils iproute2 iw rfkill kmod
    else
        printf 'Administrator access is unavailable. Continuing with existing tools.\n'
        return 0
    fi
    if (( $? == 0 )); then
        INSTALL_STATUS='APT dependency installation completed successfully.'
    else
        INSTALL_STATUS='APT dependency installation failed or was declined; collecting with existing tools.'
        printf '%s\n' "$INSTALL_STATUS"
        printf 'If package lists are outdated, run sudo apt update and try again later.\n'
    fi
}

# Keep APT output and prompts visible in the terminal.
install_dependencies

section() { printf '\n=== %s ===\n' "$1"; }
run() {
    if command -v "$1" >/dev/null 2>&1; then
        "$@"
        local status=$?
        if (( status != 0 )); then
            printf '[Command exited with status %s: %s]\n' "$status" "$*"
        fi
    else
        printf '[Command unavailable: %s]\n' "$1"
    fi
}
kernel_log() {
    if [[ $JOURNAL_MODE == sudo ]]; then
        sudo -n journalctl -k -b --no-pager -o short-monotonic
    else
        journalctl -k -b --no-pager -o short-monotonic
    fi
}

{
    printf 'LENOVO WIFI DIAGNOSTIC REPORT\nDate: %s\n' "$(date -Is)"
    section 'OPERATING SYSTEM'
    cat /etc/os-release
    run uname -r
    section 'DEPENDENCY SETUP'
    printf '%s\n' "$INSTALL_STATUS"

    # Keep the full PCI listing so a disappearing device or its bridge is visible.
    section 'ALL PCI HARDWARE AND DRIVER BINDINGS'
    run lspci -nnk
    section 'PCI TOPOLOGY'
    run lspci -t
    section 'NETWORK INTERFACES'
    run ip -br link
    section 'WIFI INTERFACES'
    run iw dev
    section 'RADIO BLOCK STATUS'
    run rfkill list
    section 'NETWORKMANAGER STATUS (OPTIONAL)'
    run nmcli general status
    run nmcli device status
    run nmcli radio all

    section 'LOADED KERNEL MODULES'
    run lsmod

    section 'CURRENT BOOT KERNEL LOG'
    printf 'Journal access mode: %s\n' "$JOURNAL_MODE"
    if command -v journalctl >/dev/null 2>&1; then
        # Retain the full kernel log to avoid losing earlier failure evidence.
        kernel_log
        status=$?
        if (( status != 0 )); then
            printf '[Kernel log collection failed, exit status %s]\n' "$status"
        fi
    else
        printf '[Command unavailable: journalctl]\n'
    fi
} 2>&1 | sed -E \
    's/([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}/[MAC REDACTED]/g' > "$LOG"

statuses=("${PIPESTATUS[@]}")
if (( statuses[1] != 0 )); then
    printf 'Failed to write report: %s\n' "$LOG" >&2
    exit 1
fi
printf 'Report saved to: %s\n' "$LOG"
printf 'Review the report for hostnames, SSIDs, serial numbers, and other personal details before sharing.\n'
