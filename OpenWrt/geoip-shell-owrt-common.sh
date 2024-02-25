#!/bin/sh

checkutil () { command -v "$1" 1>/dev/null; }

check_owrt_init() {
	set +f
	for f in /etc/rc.d/S*"${p_name}-init"; do
		[ -s "$f" ] && { set -f; return 0; }
	done
	set -f
	return 1
}

check_owrt_include() { [ "$(uci -q get firewall."$p_name_c".enabled)" = 1 ]; }

# check for OpenWrt firewall version
checkutil uci && checkutil procd && for i in 3 4; do
	[ -x /sbin/fw$i ] && export _OWRTFW="$i"
done || {
	_msg="Failed to detect OpenWrt firewall"
	echo "$_msg" >&2
	logger -t "$me" "$_msg"
	return 1
}

me="${0##*/}"
p_name_c="${p_name%%-*}_${p_name#*-}"