FINAL vyOS: (CHANGE PASSWORD TOO)
```
configure
set system login user vyos authentication plaintext-password 'thespyfromteamfortress2'
set service ssh disable-password-authentication

# --- 1. Destination NAT Rules ---
set nat destination rule 10 destination address '172.25.26.140'
set nat destination rule 10 inbound-interface name eth0
set nat destination rule 10 protocol 'tcp'
set nat destination rule 10 destination port '443'
set nat destination rule 10 translation address '172.20.240.101'

# Rule 20: Split into TCP and UDP for DNS (VyOS compatibility)
set nat destination rule 20 destination address '172.25.26.155'
set nat destination rule 20 inbound-interface name eth0
set nat destination rule 20 protocol 'tcp_udp'
set nat destination rule 20 destination port '53'
set nat destination rule 20 translation address '172.20.240.102'

set nat destination rule 30 destination address '172.25.26.39'
set nat destination rule 30 inbound-interface name eth0
set nat destination rule 30 protocol 'tcp'
set nat destination rule 30 destination port '25,465,587'
set nat destination rule 30 translation address '172.20.242.40'

set nat destination rule 31 destination address '172.25.26.30'
set nat destination rule 31 inbound-interface name eth0
set nat destination rule 31 protocol 'tcp'
set nat destination rule 31 destination port '110,995'
set nat destination rule 31 translation address '172.20.242.40'

set nat destination rule 40 destination address '172.25.26.11'
set nat destination rule 40 inbound-interface name eth0
set nat destination rule 40 protocol 'tcp'
set nat destination rule 40 destination port '80'
set nat destination rule 40 translation address '172.20.242.30'

# --- 2. Static Routing ---
set protocols static route 172.20.242.0/24 next-hop 172.16.101.254
set protocols static route 172.20.240.0/24 next-hop 172.16.102.254

# --- 3. Firewall Global Options ---
set firewall global-options state-policy established action 'accept'
set firewall global-options state-policy related action 'accept'
set firewall global-options log-stats

# --- 4. Firewall Groups/Names ---

# TO_EXTERNAL: Internal to Internet
set firewall ipv4 name TO_EXTERNAL default-action 'drop'
set firewall ipv4 name TO_EXTERNAL rule 10 action 'accept'
set firewall ipv4 name TO_EXTERNAL rule 10 state 'new'

# RETURN_ONLY: Internet to Internal (FIXED: Added rules for NATed traffic)
set firewall ipv4 name RETURN_ONLY default-action 'drop'
set firewall ipv4 name RETURN_ONLY rule 10 action 'accept'
set firewall ipv4 name RETURN_ONLY rule 10 description 'Allow Port 443 to Web'
set firewall ipv4 name RETURN_ONLY rule 10 destination address '172.20.240.101'
set firewall ipv4 name RETURN_ONLY rule 10 destination port '443'
set firewall ipv4 name RETURN_ONLY rule 10 protocol 'tcp'
set firewall ipv4 name RETURN_ONLY rule 20 action 'accept'
set firewall ipv4 name RETURN_ONLY rule 20 description 'Allow Port 53 to DNS'
set firewall ipv4 name RETURN_ONLY rule 20 destination address '172.20.240.102'
set firewall ipv4 name RETURN_ONLY rule 20 destination port '53'
set firewall ipv4 name RETURN_ONLY rule 20 protocol 'tcp_udp'
set firewall ipv4 name RETURN_ONLY rule 30 action 'accept'
set firewall ipv4 name RETURN_ONLY rule 30 description 'Allow SMTP/IMAP to Webmail'
set firewall ipv4 name RETURN_ONLY rule 30 destination address '172.20.242.40'
set firewall ipv4 name RETURN_ONLY rule 30 destination port '25,465,587,110,995'
set firewall ipv4 name RETURN_ONLY rule 30 protocol 'tcp'
set firewall ipv4 name RETURN_ONLY rule 40 action 'accept'
set firewall ipv4 name RETURN_ONLY rule 40 description 'Allow Port 80'
set firewall ipv4 name RETURN_ONLY rule 40 destination address '172.20.242.30'
set firewall ipv4 name RETURN_ONLY rule 40 destination port '80'
set firewall ipv4 name RETURN_ONLY rule 40 protocol 'tcp'

# WEBMAIL_TO_AD: Inter-zone communication
set firewall ipv4 name WEBMAIL_TO_AD default-action 'drop'
set firewall ipv4 name WEBMAIL_TO_AD rule 10 action 'accept'
set firewall ipv4 name WEBMAIL_TO_AD rule 10 description 'Allow Webmail to AD/DNS'
set firewall ipv4 name WEBMAIL_TO_AD rule 10 source address '172.20.242.40'
set firewall ipv4 name WEBMAIL_TO_AD rule 10 destination address '172.20.240.102'
set firewall ipv4 name WEBMAIL_TO_AD rule 10 state 'new'

# NET1_TO_LOCAL: Management and Infrastructure
set firewall ipv4 name NET1_TO_LOCAL default-action 'drop'
set firewall ipv4 name NET1_TO_LOCAL rule 10 action 'accept'
set firewall ipv4 name NET1_TO_LOCAL rule 10 description 'Management Access'
set firewall ipv4 name NET1_TO_LOCAL rule 10 source address '172.16.101.50'
set firewall ipv4 name NET1_TO_LOCAL rule 10 destination port '22'
set firewall ipv4 name NET1_TO_LOCAL rule 10 protocol 'tcp'
set firewall ipv4 name NET1_TO_LOCAL rule 20 action 'accept'
set firewall ipv4 name NET1_TO_LOCAL rule 20 description 'DNS and NTP'
set firewall ipv4 name NET1_TO_LOCAL rule 20 destination port '53,123'
set firewall ipv4 name NET1_TO_LOCAL rule 20 protocol 'udp'
set firewall ipv4 name NET1_TO_LOCAL rule 30 action 'accept'
set firewall ipv4 name NET1_TO_LOCAL rule 30 icmp type-name 'destination-unreachable'
set firewall ipv4 name NET1_TO_LOCAL rule 30 protocol 'icmp'
set firewall ipv4 name NET1_TO_LOCAL rule 31 action 'accept'
set firewall ipv4 name NET1_TO_LOCAL rule 31 icmp type-name 'time-exceeded'
set firewall ipv4 name NET1_TO_LOCAL rule 31 protocol 'icmp'

set firewall ipv4 name NET2_TO_LOCAL default-action 'drop'
set firewall ipv4 name NET2_TO_LOCAL rule 10 action 'accept'
set firewall ipv4 name NET2_TO_LOCAL rule 10 description 'DNS and NTP'
set firewall ipv4 name NET2_TO_LOCAL rule 10 destination port '53,123'
set firewall ipv4 name NET2_TO_LOCAL rule 10 protocol 'udp'
set firewall ipv4 name NET2_TO_LOCAL rule 20 action 'accept'
set firewall ipv4 name NET2_TO_LOCAL rule 20 icmp type-name 'destination-unreachable'
set firewall ipv4 name NET2_TO_LOCAL rule 20 protocol 'icmp'

# --- 5. Zone Definitions ---
set firewall zone EXTERNAL interface 'eth0'
set firewall zone EXTERNAL default-action 'drop'
set firewall zone EXTERNAL default-log

set firewall zone NET1_PA interface 'eth1'
set firewall zone NET1_PA default-action 'drop'
set firewall zone NET1_PA default-log

set firewall zone NET2_CISCO interface 'eth2'
set firewall zone NET2_CISCO default-action 'drop'
set firewall zone NET2_CISCO default-log

set firewall zone LOCAL local-zone
set firewall zone LOCAL default-action 'drop'
set firewall zone LOCAL default-log

# --- 6. Zone Policy Assignments ---
# Internet Traffic
set firewall zone EXTERNAL from NET1_PA firewall name 'TO_EXTERNAL'
set firewall zone EXTERNAL from NET2_CISCO firewall name 'TO_EXTERNAL'
set firewall zone NET1_PA from EXTERNAL firewall name 'RETURN_ONLY'
set firewall zone NET2_CISCO from EXTERNAL firewall name 'RETURN_ONLY'

# Router Access (Local)
set firewall zone LOCAL from NET1_PA firewall name 'NET1_TO_LOCAL'
set firewall zone LOCAL from NET2_CISCO firewall name 'NET2_TO_LOCAL'
set firewall zone EXTERNAL from LOCAL firewall name 'TO_EXTERNAL'
set firewall zone LOCAL from EXTERNAL firewall name 'RETURN_ONLY'

# Inter-Zone Traffic
set firewall zone NET2_CISCO from NET1_PA firewall name 'WEBMAIL_TO_AD'

# --- 7. Services & System ---
set interfaces ethernet eth0 ip source-validation 'loose'
set interfaces ethernet eth1 ip source-validation 'loose'
set interfaces ethernet eth2 ip source-validation 'loose'

delete system conntrack modules

delete service ntp allow-client
set service ntp allow-client address '172.16.101.0/24'
set service ntp allow-client address '172.16.102.0/24'

set system syslog host 172.20.242.20 facility all level 'info'
set system syslog host 172.20.242.20 protocol 'udp'

# Split name-server commands (FIXED)
delete system name-server 8.8.8.8
set system name-server 172.20.240.102

set service dns forwarding listen-address '172.16.101.1'
set service dns forwarding listen-address '172.16.102.1'
delete service dns forwarding allow-from 0.0.0.0/0 
set service dns forwarding allow-from '172.16.101.0/24'
set service dns forwarding allow-from '172.16.102.0/24'

# --- 8. Source NAT ---
delete nat source rule 101
set nat source rule 100 outbound-interface name 'eth0'
set nat source rule 100 source address '172.16.0.0/12'
set nat source rule 100 translation address 'masquerade'



```


### Palo Alto
```
request system software check
request system software download version 11.2.0
show jobs id <job_id>
request system software download 11.2.10-h2
show jobs id <job_id>
(may need to wait a moment for the FW to notice the download)
(!Must update Content Database, find CLI commands for that!)
request system software install version 11.2.10-h2
request restart system
```

CHANGE PASSWORD?

```

# Change the admin password (run from operational mode, not configure) 
set password 


# 1. Fix the Splunk Log Validation Error
# This clears the broken syslog setting causing the commit failure
delete log-settings syslog Splunk_Server

# 2. Define Service Objects (Prevents 'not a valid reference' errors)
set service service-ldap protocol tcp port 389
set service service-splunk-9997 protocol tcp port 9997
set service service-smtp protocol tcp port 25
set service service-smtps protocol tcp port 465
set service service-submission protocol tcp port 587
set service service-pop3 protocol tcp port 110
set service service-pop3s protocol tcp port 995
set service service-http protocol tcp port 80

# 3. Define Address Objects
set address Webmail_Fedora ip-netmask 172.20.242.40
set address Ecom_Ubuntu ip-netmask 172.20.242.30
set address Splunk_Server ip-netmask 172.20.242.20
set address AD_DNS_Server ip-netmask 172.20.240.102
set address Web_Server_2019 ip-netmask 172.20.240.101
set address FTP_Server_2022 ip-netmask 172.20.240.104
set address Wkst_Win11 ip-netmask 172.20.240.100

# 4. Define Address Groups and Routing
set address-group Windows_Forwarders static [ AD_DNS_Server Web_Server_2019 FTP_Server_2022 Wkst_Win11 ]
set network virtual-router default routing-table ip static-route VyOS-Edge destination 0.0.0.0/0 nexthop ip-address 172.16.101.1
set network virtual-router default routing-table ip static-route Internal-Windows-Subnet destination 172.20.240.0/24 nexthop ip-address 172.16.101.1

# 5. Security Policies (Using existing 'internal' and 'external' zones)
set rulebase security rules Allow_Webmail_LDAP from internal to external source Webmail_Fedora destination AD_DNS_Server service service-ldap action allow
set rulebase security rules Splunk_to_Windows from internal to external source Splunk_Server destination Windows_Forwarders service service-splunk-9997 action allow
set rulebase security rules Inbound_Mail from external to internal source any destination Webmail_Fedora service [ service-smtp service-smtps service-submission service-pop3 service-pop3s ] action allow
set rulebase security rules Inbound_Ecom from external to internal source any destination Ecom_Ubuntu service service-http action allow
set rulebase security rules Allow_Ping from external to any source any destination any application icmp action allow

# 6. Global Hardening (Implicit Deny)
set rulebase security rules DEFAULT_DENY_ALL from any to any source any destination any action drop log-start yes


# Check for and download latest content (Apps and Threats)
request content upgrade check
request content upgrade download latest

# Monitor progress with 'show jobs all'
request content upgrade install version latest

# Restrict management access to specific source IPs (e.g., your admin subnet)
set deviceconfig system permitted-ip 172.20.242.0/24 

# Disable insecure management protocols
set deviceconfig setting management http-port 0
set deviceconfig setting management telnet-port 0

# Create a strict Vulnerability Protection profile
set profiles vulnerability Hardened_Vuln_Profile rules Default_Strict action block

# Attach profiles to your 'Inbound_Mail' rule
set rulebase security rules Inbound_Mail profile-setting group default

# Ensure logging is enabled for all rules to feed Splunk
set rulebase security rules Inbound_Mail log-end yes

# Create and apply Anti-Spyware (Strict)
set profiles spy-ware Hardened_Spyware_Profile rules Default_Strict action block
set rulebase security rules Inbound_Mail profile-setting profiles spy-ware Hardened_Spyware_Profile

# Create and apply Antivirus (Strict)
set profiles virus Hardened_AV_Profile ml-av-model-analysis [ alert ]
set rulebase security rules Inbound_Mail profile-setting profiles virus Hardened_AV_Profile

# Apply the Vulnerability profile you created earlier to ALL relevant rules
set rulebase security rules Allow_Webmail_LDAP profile-setting profiles vulnerability Hardened_Vuln_Profile
set rulebase security rules Inbound_Ecom profile-setting profiles vulnerability Hardened_Vuln_Profile

# Create Zone Protection Profile
set network profiles zone-protection Hardened_Zone_Prot flood tcp-syn enable yes
set network profiles zone-protection Hardened_Zone_Prot flood tcp-syn alert-threshold 10000
set network profiles zone-protection Hardened_Zone_Prot flood tcp-syn activate-threshold 10000
set network profiles zone-protection Hardened_Zone_Prot flood tcp-syn drop-threshold 40000

# Attach to your external zone
set zone external network zone-protection Hardened_Zone_Prot



commit
```