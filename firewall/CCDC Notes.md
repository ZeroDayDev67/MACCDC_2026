## Updating Firewall(s)
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

## Hardening
### vyOS
```
configure
set system login user vyos authentication plaintext-password 'VERY-STRONG-PASSWORD'
set service ssh disable-password-authentication
delete service ntp allow-client
set service ntp allow-client address 172.16.101.0/24
set service ntp allow-client address 172.16.102.0/24
set system syslog host 172.20.242.20 facility all level info
set system syslog host 172.20.242.20 protocol udp
delete system conntrack modules
set interfaces ethernet eth0 ip source-validation strict
set interfaces ethernet eth1 ip source-validation strict
set interfaces ethernet eth2 ip source-validation strict
set firewall zone EXTERNAL default-action drop
set firewall zone EXTERNAL interface eth0
set firewall zone NET1_PA default-action drop
set firewall zone NET1_PA interface eth1
set firewall zone NET2_CISCO default-action drop
set firewall zone NET2_CISCO interface eth2
set firewall zone LOCAL default-action drop
set firewall zone LOCAL local-zone
set firewall ipv4 name ALLOW_ESTABLISHED_RELATED rule 10 action accept
set firewall ipv4 name ALLOW_ESTABLISHED_RELATED rule 10 state established
set firewall ipv4 name ALLOW_ESTABLISHED_RELATED rule 10 state related
set firewall zone EXTERNAL from LOCAL firewall name ALLOW_ESTABLISHED_RELATED
set firewall zone LOCAL from EXTERNAL firewall name ALLOW_ESTABLISHED_RELATED
set firewall zone EXTERNAL from NET1_PA firewall name ALLOW_ESTABLISHED_RELATED
set firewall zone EXTERNAL from NET2_CISCO firewall name ALLOW_ESTABLISHED_RELATED

```

set interfaces ethernet eth0 ip source-validation loose
set interfaces ethernet eth1 ip source-validation loose
set interfaces ethernet eth2 ip source-validation loose

