# Linux Wi-Fi Diagnostics

A small Bash script that collects information when Wi-Fi stops working or a wireless adapter disappears. Designed for Debian 12/13 and Fedora, with no network configuration changes. On Debian, it installs missing diagnostic utilities before collecting the report.

It creates a text report for troubleshooting or a manufacturer support request. It does not diagnose a hardware defect automatically.

## What you need

- A Linux computer with Bash. Run this on the computer experiencing the problem.
- A terminal: look for **Terminal** in your applications menu.
- Administrator access to install missing utilities on Debian and read the complete kernel log. The script asks for your `sudo` password if `sudo` is available; without access, it collects whatever information is available.

**Validation:** Bash syntax and dependency setup behavior have been checked using mocked commands. Compatibility was reviewed against Debian 12 and 13 documentation; actual package installation and collection have not yet been tested on the affected Debian laptop. Other distributions may work but are not verified.

## 1. Download the script

On this GitHub page, open **wifi-diagnostics.sh**, click **Raw**, and save the page as `wifi-diagnostics.sh` in your **Downloads** folder. Make sure your browser does not add `.txt` to the filename.

Alternatively, paste these commands into a terminal:

```bash
mkdir -p ~/Downloads
curl -fL https://raw.githubusercontent.com/EnalDeeb/linux-wifi-diagnostics/main/wifi-diagnostics.sh -o ~/Downloads/wifi-diagnostics.sh
```

If `curl` is unavailable, use the browser method. If the affected computer is offline, download the file on another computer and copy it over using a USB drive.

Read the downloaded script before running it. You can open it in a text editor or display it in the terminal:

```bash
cat ~/Downloads/wifi-diagnostics.sh
```

## 2. Run it

Paste this into your terminal and press Enter:

```bash
bash ~/Downloads/wifi-diagnostics.sh
```

Run it as your normal user. You do not need `chmod +x` or to run the whole script with `sudo`.

On Debian 12/13, the script checks for `lspci`, `ip`, `iw`, `rfkill`, and `lsmod`. If any are missing, it runs `sudo apt install pciutils iproute2 iw rfkill kmod` (or `apt install` when already root). APT may ask whether to proceed: review its proposed changes, type `Y`, and press Enter to install. If all tools are available, installation is skipped. Fedora dependency installation remains manual.

If asked for a `sudo` password, enter your Linux account password. The terminal normally shows no characters while you type. Press Enter when finished. If administrator access is unavailable, the script continues, but its kernel log may be incomplete.

The final message shows the report path, for example:

```text
Report saved to: /home/yourname/lenovo-wifi-20261012-153000-AbCdEf.txt
```

`~` means your home folder. Open **Home** in your file manager to find the report. Each run creates a separate file readable and writable only by its owner, subject to administrator access.

## 3. If a command is missing

The report explicitly labels unavailable commands. This is common on minimal installations.

On **Debian 12/13**, the script attempts this installation automatically when required. You can also run it manually:

```bash
sudo apt install pciutils iproute2 iw rfkill kmod
```

Installation changes your system and may need internet access. If it fails or you decline it, the script continues and labels missing commands in the report. If package lists are outdated, run `sudo apt update` and retry. If you do not have `sudo` access, ask your system administrator to install the missing utilities.

The `nmcli` command belongs to NetworkManager. If your system uses another network manager, missing `nmcli` is expected. You do not need to install or switch network managers to use this script.

## 4. Capture useful evidence

For intermittent failures:

1. Run the script once while Wi-Fi works.
2. Run it again immediately after Wi-Fi fails, **before restarting**.
3. Keep both reports and note which one shows the failure.
4. Write down what happened just before the failure: starting the computer, waking from sleep, normal use, or another event.
5. Note whether a subsequent reboot or a different installed kernel restores Wi-Fi.

Preserve the failing report before attempting driver resets, firmware updates, or BIOS changes.

An adapter missing from PCI enumeration is useful evidence, but it does not by itself prove a hardware defect. A support technician can compare the device listings, kernel versions, driver bindings, and kernel messages.

## What the report contains

- Operating system and kernel version
- All PCI devices, numeric IDs, driver bindings, and PCI topology
- Network and wireless interfaces
- Radio blocking status
- NetworkManager status, when available
- Loaded kernel modules
- The complete available kernel log from the current boot

The script may install diagnostic packages on Debian, then reads system information and writes one report in your home folder. It issues no commands to restart services, change radio settings, unload drivers, or update firmware. `sudo` is used for dependency installation and kernel log access.

## Privacy: review before sharing

The script replaces conventional colon-separated MAC addresses with `[MAC REDACTED]`. This is **partial redaction**, not complete anonymization.

Reports may still contain hostnames, Wi-Fi network names (SSIDs), IP addresses, serial numbers, disk identifiers, or other identifying information, especially in kernel messages. Some address formats may also evade the MAC filter. Review a copy of the report and remove personal details before sending it anywhere.

Do not upload an unreviewed report to a public GitHub issue. Keep the original privately, and share a sanitized copy or send it through your manufacturer's private support channel.

## Troubleshooting

**“No such file or directory” when running the script:** Check your Downloads folder and the filename. If you saved it somewhere else, substitute the correct path in the `bash` command.

**No wireless interface listed:** Keep the report. An empty wireless listing can be relevant evidence; compare it with the full PCI listing and a working report.

**NetworkManager is not running:** The script records the error and continues. Your system may use another networking service.

**Kernel log permission error or “No journal files were found”:** The report may lack usable kernel evidence. Check whether the script obtained administrator access and whether your system uses the systemd journal.

**Wi-Fi is already broken and packages cannot be downloaded:** Run the script with the tools already installed to preserve evidence. Install missing tools later using Ethernet, USB tethering, or another available connection.

## References

- [Debian 12 operating system identification (`os-release`)](https://manpages.debian.org/bookworm/systemd/os-release.5.en.html)
- [Debian 12 PCI inspection (`lspci`)](https://manpages.debian.org/bookworm/pciutils/lspci.8.en.html)
- [Debian Wi-Fi documentation](https://wiki.debian.org/WiFi)
- [Debian 12 NetworkManager package](https://packages.debian.org/en/bookworm/network-manager)

## License

MIT. See [LICENSE](LICENSE).
