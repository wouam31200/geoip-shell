## **Prelude**
- This document mainly intends to provide some info on the purpose and core options of the main scripts and how they work in tandem.
- The main scripts display "usage" when called with the "-h" option. You can find out about some additional options specific to each script by running it with that option.

## **Overview**

### Main Scripts
1. geoip-shell-install.sh
2. geoip-shell-uninstall.sh
3. geoip-shell-manage.sh
4. geoip-shell-run.sh
5. geoip-shell-fetch.sh
6. geoip-shell-apply.sh
7. geoip-shell-backup.sh
8. geoip-shell-cronsetup.sh

### Helper Script
This script is only used under specific conditions:
- During installation, if installing in whitelist mode, and only if wan interfaces were set to 'all', and lan subnets were not specified via command line args. The suite then assumes that it is being installed on a machine belonging to a LAN, uses this script to detect the LAN subnets and offers the user to add them to the whitelist, and to enable automatic detection of LAN subnets in the future.
- At the time of creating/updating firewall rules, and only if LAN subnets automatic detection was enabled during installation. The suite then re-detects and refreshes the LAN subnets in the whitelist automatically. Otherwise the script does not get installed.
1. geoip-shell-detect-lan.sh

### Library Scripts
- The 'library' term is used loosely as some of these scripts actually do some work by themselves. In particular, the lib-apply scripts. What's common to all of them is that they are sourced from other scripts rather than called to run as an individual script.
- The -common script includes a large number of functions used throughout the suite, and assigns some essential variables.
- The -setvars script sets some system-specific variables (such as the PATH environment variable, the detected init system, paths to some directories etc). It is sourced from the -common script. The distribution version stores some initial values. During installation, the -install script creates a new version and adds the required variables to it. It is stored in the config directory rather than in /usr/bin as other scripts because it essentially a part of the config which is simply more convenient to implement as a script, and the installed version contains some potentially sensitive data which should not be readable by unprivileged users.
- The -ipt and -nft scripts implement support for iptables and nftables, respectively. They are sourced from the main scripts which need to interact with the firewall utility directly.
- When nftables is present during installation, the iptables libraries are not installed.
- When nftables is not present (and iptables is), both -ipt and -nft libraries are installed, so if you ever upgrade your system to nftables, the suite shouldn't break.
- The lib-arrays script implements a minimal subset of functions emulating the functionality of associative arrays in POSIX-compliant shell. It is used in the -fetch script. It is a part of a larger project implementing much more of the arrays functionality. You can check my other repositories if you are interested.
- The lib-ip-regex script stores regex patterns used in several other scripts for ip addresses validation.
1. geoip-shell-common.sh
2. lib/geoip-shell-lib-ipt.sh
3. lib/geoip-shell-lib-nft.sh
4. lib/geoip-shell-lib-apply-ipt.sh
5. lib/geoip-shell-lib-apply-nft.sh
6. lib/geoip-shell-lib-backup-ipt.sh
7. lib/geoip-shell-lib-backup-nft.sh
8. lib/geoip-shell-lib-status-ipt.sh
9. lib/geoip-shell-lib-status-nft.sh
10. lib/geoip-shell-lib-arrays.sh
11. lib/geoip-shell-lib-ip-regex.sh

### OpenWrt-specific scripts
These are only installed on OpenWrt systems. The .tpl files are "templates" which are used to create the final scripts at the time of installation.
1. geoip-shell-owrt-common.sh
2. geoip-shell-owrt-init.tpl
3. geoip-shell-owrt-mk-fw-include.tpl
2. geoip-shell-owrt-fw-include.tpl

### Optional script
This script is intended for checks before installation. It does not get installed.
1. check-ip-in-source.sh

### User interface
The scripts intended as user interface are **geoip-shell-install.sh**, **geoip-shell-uninstall.sh**, **geoip-shell-manage.sh** and **check-ip-in-source.sh**. All the other scripts are intended as a back-end. If you just want to install and move on, you only need to run the -install script.
After installation, the user interface is provided by running "geoip-shell", which is a symlink to the -manage script.

## **Main scripts in detail**
**geoip-shell-install.sh**
- Processes command line arguments, then, if needed, asks the user additional questions.
- Creates directories for config and data.
- Sets permissions for the data directory to be only readable and writable by root. The config directory is currently readable by any local user, writable only by root. While there is no particularly sensitive information stored in the config, an upcoming release will make it only readable by root to further improve security.
- Copies the scripts to `/usr/bin`, config to `/etc/geoip-shell`, and creates a directory for data in `/var/lib/geoip-shell` (or in `/etc/geoip-shell/data` on OpenWrt).
- Sets the initial config.
- Calls the -manage script to set up geoip (which, in turn, calls additional scripts).
- If an error occurs during the installation, it is propagated back through the execution chain and eventually the -install script calls the -uninstall script to revert any changes made to the system.
- Installation is possible either fully interactively (no command line arguments required), partially interactively (you provide some command line arguments, the install script processes them and if needed, asks you additional questions), or completely non-interactively by calling the install script with the `-z` option which will force installation failure if any required options are missing or invalid.
- The -install script does not install itself into the system.

Options:
- `-m <whitelist|blacklist>`: geoip blocking mode
- `-c <"[country_codes]">`: country codes to include in the whitelist or blacklist
- `-u <ripe|ipdeny>`: specify source to fetch the ip lists from. Currently supports 'ripe' and 'ipdeny'. Defaults to ipdeny for OpenWrt, to ripe for all other systems.
- `-i <"[ifaces]"|auto|all>`: specify whether firewall rules will be applied to specific network interface(s), to autodetected WAN interfaces or to all network interfaces.
- `-l <"[lan_subnets]"|auto|none>`: when installing in whitelist mode and for all network interfaces, specify LAN subnets to exclude from blocking, otherwise they will get blocked. `auto` will automatically detect LAN subnets at the time of installation and then later, each time when updating firewall rules and ip sets. If the machine has dedicated WAN interfaces, `auto` may misdetect the WAN subnet as LAN subnet. So don't use `auto` in this situation. The `-l` option is incompatible with blacklist mode (and the install script will not allow this combination).
- `-t <"[trusted_subnets]">` : optional list of trusted subnets anywhere on the Internet to exclude from geoip blocking.
- `-r <[user_country_code]|none>`: Specify user's country code. Used to prevent accidental lockout of a remote machine. `none` disables this feature.
- `-f <ipv4|ipv6|"ipv4 ipv6">`: specify the ip protocol family (ipv4 or ipv6). Defaults to both.
- `-p <tcp|udp>:<allow|block>:<all|[ports]>`: specify ports geoip blocking will apply (or not apply) to, for tcp or udp. To specify ports for both protocols, use the `-p` option twice in one command. For more details, read [NOTES.md](/Documentation/NOTES.md), sections 8-10.
- `-s <"[schedule_expression]"|disable>`: specify custom cron schedule expression for the autoupdate schedule. Default cron schedule is "15 4 * * *" - at 4:15 [am] every day, or "15 4 * * 5" for OpenWrt - each Friday at 4:15am. 'disable' instead of the schedule will disable autoupdates.
- `-n`: disable persistence (reboot cron job won't be created so after system reboot, there will be no more geoip blocking - unless the autoupdate cron job kicks in).
- `-o`: disable automatic backups of the firewall geoip rules and geoip config. Backups are used both as a backup, and for persistence. Meaning that the ip lists are loaded from the backup at reboot. Installation with this option will avoid using permanent storage for the ip lists but will trigger ip lists re-fetch at reboot. Backup compresses the downloaded ip lists using the best compression tool available in the system. This option is only useful for devices with very small storage size (backup of a dozen of large ip lists takes around 0.5MB).
- `-k`: skip adding the geoip 'enable' rule. This can be used if you want to install and check the rules before commiting to actual geoip blocking. To enable blocking later, use the *manage script.
- `-e`: create nftables sets with the 'performance' optimization policy (defaults to 'memory' policy to optimize for low memory consumption)

**geoip-shell-uninstall.sh**
- Removes geoip firewall rules, geoip cron jobs, scripts' data and config, and deletes the scripts from /usr/bin

Advanced options:
- `-l`: cleans up previous firewall geoip rules and resets the ip lists in the config
- `-c`: cleans up previous firewall geoip rules, removes geoip cron jobs and resets the ip lists in the config
- `-r`: prepares the system for re-installation of the suite: cleans up previous firewall geoip rules, removes the cron jobs (and the OpenWrt-specific scripts) and removes the config.

**geoip-shell-manage.sh**: serves as the main user interface to configure geoip after installation. You can also call it by simply typing `geoip-shell`. As most scripts in this suite, it requires root privileges because it needs to interact with the netfilter kernel component and access the data folder which is only readable and writable by root. Since it serves as the main user interface, it really implements a lot of logic to generate a report, parse, validate and initiate actions requested by the user (by calling other scripts as required), check for possible remote machine lockout and warn the user about it, check actions result, update the config and take corrective actions in case of an error. Describing all this is beyond the scope of this document but you can read the code. Sources the lib-status-ipt or lib-status-nft when generating a status report.

`geoip-shell <on|off> [-c <"country_codes">]` : Enable or disable the geoip blocking chain (via a rule in the base geoip chain)

`geoip-shell <add|remove> [-c <"country_codes">]` :
* Adds or removes the specified country codes to/from the config file.
* Calls the -run script to fetch the ip lists for specified countries and apply them to the firewall (or to remove them).

`geoip-shell status`
* Displays information on the current state of geoip blocking
* For a list of all firewall rules in the geoip chain, run `geoip-shell status -v`.

`geoip-shell schedule -s <"schedule_expression">` : enables automatic ip lists update and configures the schedule for the periodic cron job which implements this feature.

`geoip-shell schedule -s disable` : disables ip lists autoupdate.

`geoip-shell restore` : re-fetches and re-applies geoip firewall rules and ip lists as per the config.

`geoip-shell apply -p [tcp|udp]:[allow|block]:[all|<ports>]`: specify ports geoip blocking will apply (or not apply) to, for tcp or udp. To specify ports for both protocols, use the `-p` option twice. For more details, read [NOTES.md](/Documentation/NOTES.md), sections 8-10.

`geoip-shell showconfig` : prints the contents of the config file.


**geoip-shell-run.sh**: Serves as a proxy to call the -fetch, -apply and -backup scripts with arguments required for each action. Executes the requested actions, depending on the config set by the -install and -manage scripts, and the command line options, and writes to system log when starting and on action completion (or if any errors encountered). If persistence or autoupdates are enabled, the cron jobs (or on OpenWrt, the firewall include script) call this script with the necessary options. If a non-fatal error is encountered during an automatic update function, the script enters sort of a temporary daemon mode where it will re-try the action (up to a certain number of retries) with increasing time intervals. It also implements some logic to account for unexpected issues encountered during the 'restore' action which runs after system reboot to impelement persistnece, such as a missing backup, and in this situation will automatically change its action from 'restore' to 'update' and try to re-fetch and re-apply the ip lists.

`geoip-shell-run add -l <"list_id [list_id] ... [list_id]">` : Fetches ip lists, loads them into ip sets and applies firewall rules for specified list id's.
A list id has the format of `<country_code>_<family>`. For example, ****US_ipv4** and **GB_ipv6** are valid list id's.

`geoip-shell-run remove -l <"list_ids">` : Removes iplists and firewall rules for specified list id's.

`geoip-shell-run update` : Updates the ip sets for list id's that had been previously configured. Intended for triggering from periodic cron jobs.

`geoip-shell-run restore` : Restore previously downloaded lists from backup (skip fetching). Used by the reboot cron job to implement persistence.

**geoip-shell-fetch.sh**
- Fetches ip lists for given list id's from RIPE or from ipdeny. The source is selected during installation. If you want to change the default which is RIPE, install with the `-u ipdeny` option.
- Parses, validates, compiles the downloaded lists, and saves each one to a separate file.
- Implements extensive sanity checks at each stage (fetching, parsing, validating and saving) and handles errors if they occur.

(for specifics on how to use the script, run it with the -h option)

**geoip-shell-apply.sh**:  directly interfaces with the firewall. Creates or removes ip sets and firewall rules for specified list id's. Sources the lib-apply-ipt or lib-apply-nft script which does most of the actual work.

`geoip-shell-apply add -l <"list_ids">` :
- Loads ip list files for specified list id's into ip sets and applies firewall rules required for geoip blocking.

List id has the format of `<country_code>_<family>`. For example, **US_ipv4** and **GB_ipv6** are valid list id's.

`geoip-shell-apply remove -l <"list_ids">` :
- removes ip sets and geoip firewall rules for specified list id's.

**geoip-shell-cronsetup.sh** manages all the cron-related logic and actions. Called by the -manage script. Cron jobs are created based on the settings stored in the config file. Also used to validate cron schedule provided by the user at the time of installation or later.

**geoip-shell-backup.sh**: Creates a backup of current geoip-shell firewall rules and ip sets and current geoip-shell config, or restores them from backup. By default (if you didn't run the installation with the '-o' option), backup will be created after every change to ip sets in the firewall. Backups are automatically compressed and de-compressed with the best utility available to the system, in this order "bzip2, xz, gzip", or simply "cat" as a fallback if neither is available (which generally should never happen on Linux). Only one backup copy is kept. Sources the lib-backup-ipt or the lib-backup-nft script which does most of the actual work.

`geoip-shell-backup create-backup` : Creates a backup of the current firewall state and geoip blocking config.

`geoip-shell-backup restore` : Restores the firewall state and the config from backup. Used by the *run script to implement persistence. Can be manually used for recovery from fault conditions.

## **Optional script in detail**
**check-ip-in-source.sh** can be used to verify that a certain ip address belongs to a subnet found in source records for a given country. It is intended for manual use and is not called from other scripts. It requires the grepcidr utility to be installed in your system.

`sh check-ip-in-source.sh -c <country_code> -i <"ip [ip] [ip] ... [ip]"> [-u <source>]`

- Supported sources are 'ripe' and 'ipdeny'.
- Any combination of ipv4 and ipv6 addresses is supported.
- If passing multiple ip addresses, use double quotes around them.
