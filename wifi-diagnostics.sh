#!/usr/bin/env bash
# Read-only Wi-Fi diagnostics for Debian 12 and Fedora.
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
