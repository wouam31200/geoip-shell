#!/bin/sh
# shellcheck disable=SC2317,SC2154,SC2086,SC2034,SC1090

# geoip-shell-uninstall

# Copyright: friendly bits
# github.com/friendly-bits

# uninstalls or resets geoip-shell


#### Initial setup
p_name="geoip-shell"
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)

manmode=1
. "$script_dir/${p_name}-common.sh" || exit 1
. "$script_dir/${p_name}-$_fw_backend.sh" || exit 1

nolog=1

check_root

san_args "$@"
newifs "$delim"
set -- $_args; oldifs

#### USAGE

usage() {
    cat <<EOF

Usage: $me [-l] [-c] [-r] [-h]

1) Removes geoip firewall rules
2) Removes geoip cron jobs
3) Deletes scripts' data folder (/var/lib/geoip-shell or /etc/geoip-shell/data on OpenWrt)
4) Deletes the scripts from /usr/sbin
5) Deletes the config folder /etc/geoip-shell

Options:
  -l  : Reset ip lists and remove firewall geoip rules, don't uninstall
  -c  : Reset ip lists and remove firewall geoip rules and cron jobs, don't uninstall
  -r  : Remove cron jobs, geoip config and firewall geoip rules, don't uninstall
  -h  : This help

EOF
}

#### PARSE ARGUMENTS

while getopts ":rlch" opt; do
	case $opt in
		l) resetonly_lists="-l" ;;
		c) reset_only_lists_cron="-c" ;;
		r) resetonly="-r" ;;
		h) usage; exit 0;;
		*) unknownopt
	esac
done
shift $((OPTIND-1))

extra_args "$@"

echo

debugentermsg

### VARIABLES
old_install_dir="$(command -v "$p_name")"
old_install_dir="${old_install_dir%/*}"
install_dir="${old_install_dir:-"$install_dir"}"

[ ! "$install_dir" ] && die "Can not determine installation directory. Try setting \$install_dir manually"

[ "$script_dir" != "$install_dir" ] && [ -f "$install_dir/${p_name}-uninstall.sh" ] && [ ! "$norecur" ] && {
	export norecur=1 # prevents infinite loop
	call_script "$install_dir/${p_name}-uninstall.sh" "$resetonly" "$resetonly_lists" "$reset_only_lists_cron" && exit 0
}

iplist_dir="$datadir/ip_lists"
conf_dir="${conf_dir:-/etc/$p_name}"
status_file="$datadir/ip_lists/status"

#### CHECKS

#### MAIN

echo "Cleaning up..."

### Remove geoip firewall rules
rm_all_georules >/dev/null || die 1

[ -f "$conf_file" ] && setconfig "Lists="
set +f; rm "$iplist_dir"/* 2>/dev/null

[ "$resetonly_lists" ] && exit 0

### Remove geoip cron jobs
crontab -u root -l 2>/dev/null | grep -v "${p_name}-run.sh" | crontab -u root -

[ "$resetonly_lists_cron" ] && exit 0

# Delete the config file
rm "$conf_file" 2>/dev/null

[ "$resetonly" ] && exit 0

# For OpenWrt
[ "$_OWRT_install" ] && {
	. "$script_dir/${p_name}-owrt-common.sh" || exit 1
	echo "Deleting the init script..."
	/etc/init.d/${p_name}-init disable && rm "/etc/init.d/${p_name}-init" 2>/dev/null
	echo "Removing the firewall include..."
	uci delete firewall."$p_name_c" 1>/dev/null 2>/dev/null
	echo "Restarting the firewall..."
	service firewall restart
}

printf '%s\n' "Deleting the data folder $datadir..."
rm -rf "$datadir"

printf '%s\n' "Deleting scripts from $install_dir..."
rm "$install_dir/$p_name" 2>/dev/null
for script_name in fetch apply manage cronsetup run uninstall backup mk-fw-include fw-include owrt-common common ipt nft \
		apply-ipt apply-nft backup-ipt backup-nft; do
	rm "$install_dir/$p_name-$script_name.sh" 2>/dev/null
done
for script_name in ip-regex posix-arrays-a-mini validate-cron-schedule check-ip-in-source detect-local-subnets-AIO; do
	rm "$install_dir/$script_name.sh" 2>/dev/null
done

echo "Deleting config..."
rm -rf "$conf_dir" 2>/dev/null

printf '%s\n\n' "Uninstall complete."
