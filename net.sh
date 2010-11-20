# $Id: net.sh,v 1.13 2010/06/01 04:14:24 merdely Exp $
# Copyright (c) 2007-2010 Michael Erdely <mike@erdelynet.com>
# Copyright (c) 2004 Waldemar Brodkorb
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

get_ifdev() {
	ifconfig -a \
	    | egrep -v '^[[:space:]]|(bridge|enc|gif|gre|lo|pflog|pfsync|ppp|sl|tun|vlan)[[:digit:]]+:' \
	    | sed -ne '1 s/^\(.*\):.*/\1/p'
}


start_net() {
	if [ -n "${DEVICE}" ]; then
		dev=${DEVICE}
	else
		dev=$(get_ifdev)
	fi

	if [ "${DHCP}" == "on" ]; then
		rm /etc/resolv.conf
		dhclient ${dev}
	else
		if [ "${SPECIAL}" == "1" ]; then
			ifconfig ${dev} ${IP} netmask ${NETMASK}
			route add -cloning -iface -ifp ${dev} ${GATEWAY} -netmask ${NETMASK} ${IP}
		else
			ifconfig ${dev} ${IP} netmask ${NETMASK}
		fi
		route add default ${GATEWAY}
		rm /etc/resolv.conf
		echo "nameserver ${DNS}" > /etc/resolv.conf
		if [ "${SEARCH}" != "" ]; then
			echo "search ${SEARCH}" >> /etc/resolv.conf
		fi
		echo "lookup file bind" >> /etc/resolv.conf
	fi	

	if [ -n "${DEVICE2}" ]; then
		ifconfig ${DEVICE2} ${IP2} netmask ${NETMASK2}
	fi
}

start_ssh() {
	/usr/sbin/sshd -e \
		-o AuthorizedKeysFile=/etc/ssh/authorized_keys \
		-o PasswordAuthentication=no \
		-o ChallengeResponseAuthentication=no \
		-o UsePrivilegeSeparation=no \
		-o UseDNS=no
}

write_netconfig() {
	if [ -n "${DEVICE}" ]; then
		dev=${DEVICE}
	else
		dev=$(get_ifdev)
	fi

	if [ "${DHCP}" == "on" ]; then
		[ ! -f /mnt/etc/hostname.${dev} ] && echo "dhcp NONE NONE NONE" > /mnt/etc/hostname.${dev}
	else
		if [ ! -f /mnt/etc/hostname.${dev} ]; then
			if [ "${SPECIAL}" == "1" ]; then
				echo "inet ${IP} ${NETMASK} NONE" > /mnt/etc/hostname.${dev}
				echo "!route add -cloning -iface -ifp ${dev} ${GATEWAY} -netmask ${NETMASK} ${IP}" >> /mnt/etc/hostname.${dev}
			else
				echo "inet ${IP} ${NETMASK} NONE" > /mnt/etc/hostname.${dev}
			fi
			chmod 640 /mnt/etc/hostname.${dev}
		fi
		[ ! -f /mnt/etc/mygate ] && echo "${GATEWAY}" > /mnt/etc/mygate
		[ ! -f /mnt/etc/resolv.conf ] && cp /etc/resolv.conf /mnt/etc/resolv.conf
	fi

	if [ -n "${DEVICE2}" -a ! -f /mnt/etc/hostname.${DEVICE2} ]; then
		echo "inet ${IP2} ${NETMASK2} NONE" > /mnt/etc/hostname.${DEVICE2}
		chmod 640 /mnt/etc/hostname.${DEVICE2}
	fi
}
