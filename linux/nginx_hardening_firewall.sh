#/bin/bash

#nginx hardening firewall

sudo iptables -A OUTPUT -m owner --uid-owner www-data -j DROP #blocks any attempt for the www-data user from accessing the internet