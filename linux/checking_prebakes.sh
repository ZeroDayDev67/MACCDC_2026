#/bin/bash

#checking prebakes

grep -rnIE --exclude-dir={proc,sys,dev,run,snap} "(sqlmap|nikto|dirbuster|hydra|wpscan|metasploit|meterpreter|rev_tcp|rev_http|shell_rev|stdapi|extapi)" /


#checking for more malicous comamnds and reverse shells
grep -rnIE --exclude-dir={proc,sys,dev,run,snap} "(cat\s+/etc/shadow|tar\s+-czf|sudo\s+-u|bash\s+-i|nc\s+-e|/dev/tcp/|curl\s+.*\|.*bash|wget\s+.*\|.*sh)" /

#looking for obfuscation and base64
grep -rnIE "[a-zA-Z0-9+/]{100,}={0,2}" /var/www /tmp /home /etc /opt

#looking for web application execution functions
grep -rnIE "(eval\(base64_decode|exec\(|system\(|shell_exec\()" /var/www/

#hunting nginx logs
grep -riE "(grep%20|find%20|cat%20/etc/shadow|tar%20-czf|sudo%20|\.\./\.\./)" /var/log/nginx/

#looking for recently dropped files
find / -type f -mtime -1 -not -path "/proc/*" -not -path "/sys/*" -not -path "/var/log/*"

#hunting rogue SUID binaries
find / -perm -4000 -type f 2>/dev/null