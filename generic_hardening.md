# Ubuntu Server Hardening

Ubuntu Server Hardening

TO DO: 

- Go through github pages  
- find and grep through with base64 and nc and msfconsole and all pre baked to make sure that they can not get in
	- go through Dylan's layer 7 rules and figure out what to find and grep for
- look into rolling the clocks back
- search for suspicous strings on the file system that might be susipciuos
- Figure out how to create self signed certificate to host web server

Only use Gpasswd do not use groupadd

172.20.19.100/16 for external kali  
172.20.19.1/16 for external router  
192.168.19.1/24 for internal router  
192.168.19.100/24 for internal kali  
192.168.19.2/24 for internal webserver

Pivot services to disable:  
"cups" "cups-browsed"  
    "avahi-daemon"  
    "nfs-server"  
    "smbd" "nmbd"  
    "xinetd"  
    "telnet"  
    "rsh" "rlogin"

Ether5 is internal

Try to run everything through firejail

Want to create script that auto removes anyone that is not the current user

START BY LOCKING ALL USERS AND SUDO \-i into root and setting root password and shut everything down

Setting up the easy typing:

```bash
#only works if you are running Ubuntu on Xorg (can change when logging in)

#install the required packages
sudo apt install xdotool 
sudo apt install xclip

#select the window
xdotool selectwindow
#select the right window and then copy that number to a variable
export WIN_ID=28288282

#function used to send the commmands
send() {
    local delay="${1:-20}" 	#default is 20, but accepts arg of time delay
    local win="$WIN_ID"
    local cmd
    cmd="$(xsel --clipboard --output)"
    xdotool type --delay "$delay" --window "$win" "$cmd"
    xdotool key  --window "$win" Return
}

#been having problems with it misinterprintg commands

```

Setup copying clipboard to VM through Python

```bash
# Setup python virtual environment
python3 -m venv venv

# Activate virtual environment
venv\Scripts\activate.bat # For Windows Command Prompt
.\venv\Scripts\activate.ps1 # For Powershell
source venv/bin/activate # For Linux or mac

# Install libraries
pip install pyautogui pyperclip

# Create python script
vim quick_copy.py 

# In the file, paste the following
import pyautogui
import pyperclip
import time
import sys

TYPING_DELAY = 0.02  
STARTUP_DELAY = 5    

print(f"[-] Copied {len(pyperclip.paste())} characters from clipboard.")
print(f"[-] You have {STARTUP_DELAY} seconds to click inside the VM console...")

for i in range(STARTUP_DELAY, 0, -1):
    print(f"{i}...", end=' ', flush=True)
    time.sleep(1)
print("\n[+] Typing started!")

text_to_type = pyperclip.paste()

try:
    pyautogui.write(text_to_type, interval=TYPING_DELAY)
    print("\n[+] Done!")
except KeyboardInterrupt:
    print("\n[!] Stopped by user.")

# Run script and change to VM screen
python quick_copy.py
```

General Commands:

```bash
general commands

jobs : show all jobs
less: tool to scroll through stuff 
passwd: change the password for current user
sudo -i: swich into the root user 
ip a: find ip addresses
sudo cp /etc/pam.d/common-auth /etc/pam.d/common-auth.bak | create a backup of a config file
ss -tnp # dumps socket statistics and displays information
ps aux # check running services
```

Kick everyone out except root:

```bash
who | awk '!/root/{ cmd="/usr/bin/pkill -KILL -u " $1; system(cmd)}'
```

How to create service that kills extra users running as root (MAY NOT WORK WELL)

```bash
# this is the script that will be running in /usr/local/bin/session-killer.sh
#!/bin/bash

while true; do
  # Kill ALL non-root users instantly
  who | awk '$1 != "root" { cmd="pkill -KILL -u " $1; system(cmd); logger "Killed non-root: " $1 }'
  
  # Count root sessions
  ROOT_COUNT=$(who | awk '$1=="root" {count++} END {print count+0}')
  
  if [ "$ROOT_COUNT" -gt 1 ]; then
    # Kill ALL root sessions except console/VNC (tty, :0, :1 patterns)
    who | awk '$1=="root" && $2 !~ /^(tty|:0|:1|:2)/ { print $2 }' | while read -r TERM; do
      pkill -KILL -t "$TERM" 2>/dev/null || killall -KILL -u root 2>/dev/null
      logger "Killed extra root on $TERM"
    done
  fi
  
  sleep 2
done


#create the service in /etc/systemd/system/session-killer.service
[Unit]
Description=Kill unauthorized sessions
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/session-killer.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

#commands to enable and start it
systemctl daemon-reload
systemctl enable session-killer.service
systemctl start session-killer.service
systemctl status session-killer.service  # Verify it's activ
```

Looking into logins

```bash
last -a # shows all login history that is stored in the /var/log/wtmp file
who -a # lists all currently logged-in users and system status 
w # shows a lot of information 
```

Find files that were recently changed in the last 24 hours

```bash
sudo find /directory -type f -mtime -1 -ls
```

Checking for .php and other files

```bash
sudo find /var/www/html -type f \( -name '*.php' -o -name '*.phtml' \)
```

Grabbing version information:

```bash
lsb_release -a
```

Locking All Users script:

```bash
getent passwd | awk -F: -v me="$(whoami)" '$3>=1000 && $1!="root" && $1!=me {print $1}' | tee locked_users.txt | xargs -I {} sh -c 'echo "Locking: {}" && sudo passwd -l "{}"'
```

Increase Logging:

```bash
sudo nano /etc/ssh/sshd_config
# add line
LogLevel VERBOSE
sudo systemctl restart ssh

sudo nano /etc/systemd/journald.conf# set Storage=persistent
# set MaxLevelStore=debug
sudo systemctl restart systemd-journald
```

Shut down SSH

```bash
sudo systemctl stop sshd.socket
sudo systemctl disable sshd.socket
sudo systemctl stop ssh.service  
sudo systemctl disable ssh.service
sudo systemctl mask ssh

# can unmask it with this
sudo systemctl unmask ssh

# Check authorized_keys files
cat ~/.ssh/authorized_keys
cat /root/.ssh/authorized_keys
cat /home/sysadmin/.ssh/authorized_keys

# Remove suspicious keys
vi /home/sysadmin/.ssh/authorized_keys

#check ssh logs
journalctl -u ssh --since "1 hour ago"


```

When locked out:

```bash
#enter into recovery mode by holding ESC
mount -o remount,rw / #used to mount the file system so that you can access it

```

Network Connections:

```bash
# list all network connections (lists all open files)
lsof -i

# shows all listening TCP/UDP sockets, process with port, and all IP addresses
netstat -tulpn 

#checks for all tcp and udp listening ports and gives ip addresses
ss -tulpn

#checks for all tcp and udp listening and all ports and resolves them to domain names and hostnanmes if possible
ss -tulpra
```

Setup faillock to lock after 3 attempts  
(HAVE TO RUN THIS AS ROOT AND NOT SUDO)

```bash
# edit the /etc/pam.d/common-auth
auth     required                        pam_faillock.so preauth silent audit
auth     [success=1 default=ignore]      pam_unix.so nullok
auth     [default=die]                   pam_faillock.so authfail
auth     sufficient                      pam_faillock.so authsucc


# dont confiugre the common-account file for sonme reason, it breaks everything
```

Setup network configuration on ubuntu

```bash
UPDATE THE /etc/netplan/<FILENAME> with this information:
   network:
      version: 2
      renderer: networkd
      ethernets:
        enp0s3: # Your interface name
          dhcp4: false
          addresses: [192.168.11.5/24] # IP Address/CIDR notation
          gateway4: 192.168.1.1 # Your router's IP
          nameservers:
            addresses: [8.8.8.8, 1.1.1.1] # DNS servers

#applies the configuration in the terminal
sudo netplan apply
```

172.18.255.105  
Firewall stuff: 

```bash
3. Enable UFW: Default deny incoming, allow only essentials.
#use sudo ufw default deny outgoing all of the time unless I specifically need to 
# Opens ports for your e-com site (80/443) and SSH (22).
sudo ufw default deny incoming
sudo ufw default allow outgoing

#only allow ports that are aboslutely necssary 
sudo ufw allow out 53/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# sets logging to full to log every packet
sudo ufw logging full

#enables and forces the commands 
sudo ufw --force enable

#disable ipv6 completely 
sudo vi /etc/default/ufw
# change the ipv6 rule to no
# then reload the firewall to apply the changes
sudo ufw reload 
```

Securing the web server

```bash
#access the base config file and make these changes
vi /etc/apache2/apach2.conf


<Directory />		#root directory
    Options None	#disbales all special features
    AllowOverride None	#makes sure that the web server follows the main configuration
    Require all denied	#completely denies access to it
</Directory>

<Directory /var/www/>	# the directory to where the files are served at
    Options -Indexes +FollowSymLinks	#prevents users from seeing directory listing
    AllowOverride None
    Require all granted	# compoletely allows everyone to access this directory

    <LimitExcept GET POST>	#blocks PUT/DELETE/etc
      Require all denied
    </LimitExcept>
</Directory>

<FilesMatch "^\.">	#blocks all files with a . in them
    Require all denied
</FilesMatch>

<FilesMatch "(^\.|\.bak|\.old|\.sql|\.zip|\.tar|\.env)$">	#blocks all of these file extensions from running (extra in case someone runs something with an extention)
    Require all denied
</FilesMatch>


#add this information to the bottom or somewhere in the config file
ServerTokens Prod	#tells the web server not to reveal its OS
ServerSignature Off	#tells it not to reveal its signature

TraceEnable off	#disables debugging trace method that can be used in Cross Site tracing attacks

Header always set X-Content-Type-Options "nosniff"	#forces the browser to a declared Content-Type rather than guessing if it is a malicious script
Header always set X-Frame-Options "SAMEORIGIN"	#prevents websites from putting <iframe> in website
Header always set X-XSS-Protection "1; mode=block"	#stops the page from loading if detecting reflected XSS attack
Header set Content-Security-Policy "default-src 'self'"	#tells the browser to only load scripts, images and CSS that came from own domain (will break Google Fonts, YouTube embeds, Bootstrap CDNs, Google Analytics, and more)



#can use the commands below to only allow a certain ip adddress
Require ip 192.168.1 #only allows ips that start with those specific numbers
Require host trusted-partner.com #only allows a specific host
```

\#look into xdotool to type commmands in faster 

Configuring the web server with HTTPS

```bash
sudo apt install resolvconf -y	#install resolvconf which tells which DNS servers to query
sudo vi /etc/resolv.conf

#specificy the nameservers of the external dns
nameserver 8.8.8.8


sudo apt update && sudo apt install certbot python3-certbot-apache -y
sudo certbot certonly --webroot -w /var/www/html -d teamX.com --server http://[CA_IP]/acme/directory

#certs will be stored here /etc/letsencrypt/live/teamX.com/



#update the conf file with this under the VirtualHost *:443 at sudo nano /etc/apache2/sites-available/default-ssl.conf

#SSL Configuration 
SSLEngine on SSLCertificateFile /etc/letsencrypt/live/teamX.com/fullchain.pem SSLCertificateKeyFile /etc/letsencrypt/live/teamX.com/privkey.pem


# to check if it worked
openssl x509 -in /etc/letsencrypt/live/yourdomain.com/cert.pem -noout -issuer

#to test connectivity to the CA
curl https://CA_IP:8443/acme/directory

#to test DNS resolution
nslookup yourdomain.competition.net

```

COPIED FROM PERPLEXITY HTTPS SETUP

```bash
#!/bin/bash
# Secure competition SSL setup - run as root

set -e  # Exit on any error

# Step 1: Create isolated directories (red team can't touch)
mkdir -p /opt/competition-{certs,ca,logs}
chown root:root /opt/competition-certs
chmod 700 /opt/competition-certs

# Step 2: Download competition CA cert (replace with actual URL)
curl -o /opt/competition-ca/ca.crt https://CA_IP:8443/ca.crt || \
echo "Download CA cert manually from competition portal to /opt/competition-ca/ca.crt"

# Step 3: Get SSL certs from competition CA using isolated config
REQUESTS_CA_BUNDLE=/opt/competition-ca/ca.crt \
certbot --apache \
  --config-dir /opt/competition-certs \
  --work-dir /opt/competition-certs/work \
  --logs-dir /opt/competition-certs/logs \
  --server https://CA_IP:8443/acme/directory \
  -d yourdomain.competition.net \
  --non-interactive --agree-tos --email admin@team.com

# Step 4: Lock down cert files (immutable + strict perms)
chattr +i /opt/competition-certs/live/yourdomain.competition.net/*
chown root:www-data /opt/competition-certs/live/yourdomain.competition.net/
chmod 640 /opt/competition-certs/live/yourdomain.competition.net/*

# Step 5: Create hardened SSL VirtualHost
cat > /etc/apache2/sites-available/competition-ssl.conf << 'EOF'
<VirtualHost *:443>
    ServerName yourdomain.competition.net
    
    DocumentRoot /var/www/html
    
    # SSL Configuration (points to isolated certs)
    SSLEngine on
    SSLCertificateFile /opt/competition-certs/live/yourdomain.competition.net/fullchain.pem
    SSLCertificateKeyFile /opt/competition-certs/live/yourdomain.competition.net/privkey.pem
    
    # Security Headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # Harden SSL protocols/ciphers
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    
    # Logging (high verbosity for competition)
    ErrorLog ${APACHE_LOG_DIR}/competition-ssl_error.log
    LogLevel trace8
    CustomLog ${APACHE_LOG_DIR}/competition-ssl_access.log combined
    
    # Block sensitive files
    <FilesMatch "\.(bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist)$">
        Require all denied
    </FilesMatch>
    
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>
</VirtualHost>
EOF

# Step 6: Configure HTTP → HTTPS redirect
cat > /etc/apache2/sites-available/000-default.conf << 'EOF'
<VirtualHost *:80>
    ServerName yourdomain.competition.net
    Redirect permanent / https://yourdomain.competition.net/
</VirtualHost>
EOF

# Step 7: Enable new site, disable defaults
a2ensite competition-ssl
a2dissite 000-default-le-ssl default-ssl

# Step 8: Firewall (only web ports)
ufw allow 80 comment 'ACME + HTTP redirect'
ufw allow 443 comment 'HTTPS'
ufw --force enable

# Step 9: Secure renewal cron (isolated, tamper-proof)
echo "0 */12 * * * REQUESTS_CA_BUNDLE=/opt/competition-ca/ca.crt certbot renew --config-dir /opt/competition-certs --quiet" | crontab -

# Step 10: Test & restart
apache2ctl configtest && systemctl restart apache2

echo "✅ SSL setup complete! Test: https://yourdomain.competition.net"
echo "Cert location: /opt/competition-certs/live/yourdomain.competition.net/"


```

OTHER HTTPS NOTES THAT I DO NOT KNOW IF CORRECT

```bash
#adds an enviornment variable before the certbot command if the CA has a self signed certificate 
sudo REQUESTS_CA_BUNDLE=/tmp/ca.crt \
  certbot --apache --server https://CA_IP/acme/directory -d yourdomain.com
```

To add a manual entry to the DNS servers can use this

```bash
sudo vi /etc/hosts

# [CA_IP]          [Domain Name]
10.0.5.50          ca.competition.local
```

Disable CUPS (printer service that has a vulnerability in it)

```bash
# disbale CUPS-browsed because it can be used to get RCE
systemctl disable cups-browsed
systemctl stop cups-browsed
systemctl mask cups-browsed

# to look through the logs
sudo cat /var/log/cups/error_log
sudo cat /var/log/cups/access_log
sudo cat /var/log/cups/page_log
journalctl -u cups | grep -E "connection|refused|denied"
sudo cat /var/log/cups/access_log | grep -v "localhost" | grep -v "127.0.0.1"
```

Adding more logging

```bash
sudo vi /etc/apache2/apache2.conf

#uncomment the lines below
[Journal]
Storage=persistent
MaxLevelStore=debug
MaxLevelSyslog=debug
MaxLevelKMsg=debug

#to apply changes at the end
sudo systemctl restart systemd-journald

#increase the logging in the apache2 web server
sudo vi /etc/apache2/apache2.conf
sudo vi /etc/apache2/sites-enabled/000-default.conf

#change this line to this
LogLevel trace8

#reload the web server to apply
sudo systemctl reload apache2
```

Checking logs

```bash
# check apache 2 logs
jorunalctl -u apache2 
```

List all active services

```bash
#lists all active services
sudo systemctl list-units --type=service
```

Securing the mysql server

```bash
sudo systemctl stop mysql      # Stop temporarily
sudo ufw deny 3306             # Block external access
sudo netstat -tlnp | grep 3306 # Verify not exposed

# edit /etc/mysql/mysql.conf.d/mysqld.cnf with localhost bind address
# also enable logging on the config file

sudo systemctl restart mysql
```

Stuff to shut down

```bash
systemctl mask sshd
systemctl mask ssh
systemctl mask sshd.socket
systemctl mask rpcbind
systemctl mask rpcbind.socket


```

sudo netstat \-tulnp | grep LISTEN | grep \-v nginx | awk '{print $7}' | awk \-F/ '{print $1}' | xargs \-I {} sudo kill \-KILL {} 2\>/dev/null && echo "All non-nginx listeners killed"

```bash
cat <<EOF | sudo tee /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

sudo printf "Types: deb\nURIs: http://archive.ubuntu.com/ubuntu/\nSuites: noble noble-updates noble-backports\nComponents: main restricted universe multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n\nTypes: deb\nURIs: http://security.ubuntu.com/ubuntu/\nSuites: noble-security\nComponents: main restricted universe multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" | sudo tee /etc/apt/sources.list.d/ubuntu.sources


#chcecking packaeges
apt-cache policy ufw




###remove any restrictions that block you from install stuff 

# Check the directory for the culprit files
ls -la /etc/apt/preferences.d/

# Delete everything in that directory (Standard Ubuntu is usually empty here)
sudo rm -rf /etc/apt/preferences.d/*

# Also check the main preferences file (rarely used, but Red Team might use it)
sudo rm /etc/apt/preferences
```

Look for the etechacademy service  
The database is initialized from our web application, as long as the `torch_bearer` user has access to the database `db`.

certbot \--nginx \--server [https://ca.ncaecybergames.org/acme/acme/directory](https://ca.ncaecybergames.org/acme/acme/directory)

/var/lib/etechacademy

RENEWING CERTIFICATES QUICKLY:

```bash
vi /lib/systemd/system/certbot.service

#change the line below
ExecStart=/usr/bin/certbot -q renew --no-random-sleep-on-renew

#reload and apply 
sudo systemctl daemon-reload
sudo systemctl restart certbot.timer

#test the renewal of the ssl certificate
sudo certbot renew --dry-run --no-random-sleep-on-renew
```

TO GET IT BACK UP AND RUNNING

```bash
ufw deny from 172.18.1.30 to any
ufw deny 8888/tcp
ufw reload

#find out what is running on port 8888 and kill it
losf -i :8888
kill -9 <process-id>

#check for suspicous outbound connections
ss -antp 

sudo certbot --nginx --server https://ca.ncaecybergames.org/acme/acme/directory -d team<T>.ncaecybergames.org

#check config
grep -r "8888" /etc/nginx/sites-enabled/

Add the Required Renewal Flag: Edit the systemd timer's service file: sudo nano /lib/systemd/system/certbot.service Change the ExecStart line to: ExecStart=/usr/bin/certbot -q renew --no-random-sleep-on-renew sudo systemctl daemon-reload

Create the file: sudo nano /usr/local/share/ca-certificates/ncae-root.crt
Paste the -----BEGIN CERTIFICATE----- block from your instructions into that file.
Update the store: sudo update-ca-certificates


#update the /etc/nginx/sites-available/default
server {
    listen 443 ssl;
    server_name team<T>.ncaecybergames.org;

    # Certbot should have filled these in, but verify:
    ssl_certificate /etc/letsencrypt/live/team<T>.ncaecybergames.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/team<T>.ncaecybergames.org/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080; # This is your Flask app
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}


#verification checklist
Is the app running? sudo systemctl status etechacademy
Is it on 8080? ss -tulpn | grep 8080
Is SSL active? Visit https://team<T>.ncaecybergames.org in a browser.
Can you log in? Use admin / admin123. If you can't, the database didn't "generate" correctly on startup.


```

```bash
systemctl stop cokpit.socket
#disable it completely


#checking conenctions
losf -i :443


#checking how dns resolves
resolvctl status

#deleting users
sudo deluser --remove-home <username>

#kills all esatblished proceses
sudo lsof -i :443 | grep ESTABLISHED | awk '{print $2}' | xargs sudo kill -9

#kill them every sing second
sudo bash -c 'while true; do lsof -t -i :443 | xargs kill -9 2>/dev/null; sleep 0.5; done' &
```

**Disable root login**

```
sudo passwd -l root
```

Iotrack.d  
Kernelguard  
Useragentd

\#remove the service compeltely that was loaded

network:  
  version: 2  
  renderer: networkd  
  ethernets:  
    ens33:  
      dhcp4: no  
      addresses:  
        \- 192.168.1.7/24  
      gateway4: 192.168.11.1  
      nameservers:  
        addresses:  
          \- 8.8.8.8  
          \- 1.1.1.1  
[https://github.com/Karmakstylez/CVE-2024-6387](https://github.com/Karmakstylez/CVE-2024-6387)

Making bash history save un reboots

```bash
#write the following to the ~/.bashrc file

# Append to the history file, don't overwrite it
shopt -s histappend

# Save every command immediately
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# Increase history size (optional but recommended)
HISTSIZE=10000
HISTFILESIZE=20000
```

Fixing problems with files executing wrong
```bash
#cat the tool filename like /usr/sbin/ufw to see if it is doing what they want it to do

```

Verifying a package
```bash
dpkg -V ufw #used to verify the ufw package
```

Checks advanced shell interpretation
```bash
type -a /usr/sbin/ufw
```

Checking file size
```bash
ls -lh filename
```

Set a DEBUG trap to make the bash system not be able to execute a certain command
```bash
shopt -s extdebug #turns on the debug status
trap 'if [[ "$BASH_COMMAND" == *ufw* ]]; then echo "I SAY NO"; return 1; fi' DEBUG #immmediately executes this before any commands are run
```

Stopping the DEBUG trap
```bash
trap - DEBUG #removes the DEBUG option happening before every command
shopt -u extdebug #turns off the extended debug option

trap #use to list active traps
```

Checking for set aliases
```bash
alias #command used to check for aliases
```

Execute command with ignoring alias
```bash
\rm #executes the rm command by ignoring the alias
```

Check shell options

```bash
shopt | grep on #checks for on shell options
```

Print variables
```bash
printenv #print enviornment variables
declare -p #prints all variables defined on the system
```

Dropping into sterile prompt
```bash
env -i bash --norc --noprofile
```

# Checking For Persistence

Check for aliases that are set in these files on boot
```bash
sudo cat /etc/profile /etc/bash.bashrc #checking the profile and config files for any aliases that might have been set

cat ~/.bash_profile ~/.bash_login ~/.profile ~/.bashrc #checking for other config files that might have malicious information
#Look for anything mentioning `ufw`, `trap`, `extdebug`, or unfamiliar functions.
```

Checking every single file for malicious files
```bash
sudo grep -rnw '/etc/' '/root/' '/home/' -e 'I SAY NO' -e 'extdebug'
```

# Checking for PreBakes
Grepping the entire file system for some suspicous tools
```bash
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
```

# NGINX

Helpful commands 

```bash
sudo nginx -t # used to test the configuration files to make sure everything is ok

#use ln -s to create a symbolic link between sites available and sites-enabled so that I do not have to edit the sites-enabled at all, just remove the symbolic link

sudo mkdir -p /var/www/maccdcprep.com/html # used to create all directories needed to make current directory

sudo chown -R root:root /var/www/maccdcprep.com/html # makes only root able to edit files for the webpage

sudo chmod -R 755 /var/www/maccdcprep.com/html #gives the owner read and write access but limits everyone else to read and execute only

#make sure to clean out /etc/nginx/sites-enabled/ directory to only allow the sites that I need to use


```

HTTPS configuration

```bash
#installs a plugin that allows certbot to automtically read Nginx configuration, fetch the certificate and rewrite nginx file to enable HTTPS without doing it manually
sudo apt install certbot python3-certbot-nginx -y #will only work if are creating something online 

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt #uses openssl to create a certificate signing request and act as its own certificates authority to create the certificate itself and saves both the crt and the private key


sudo vi /etc/nginx/sites-available/maccdcprep.com
#add the following in below
#can just remove the port 80 server if don't need it
#in the port 80 http server option
return 301 https://$host$request_uri; #forwards all traffic to https

#put this at the very beginning to make sure it only resolves the dns name and nothing will be served back by default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;
    
    # Point to dummy certs so it doesn't crash on HTTPS requests
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    # 444 is a special Nginx code that means "Close the connection immediately with no response"
    return 444; 
}


#for https part 
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name maccdcprep.com www.maccdcprep.com;

    root /var/www/maccdcprep.com/html;
    index index.html index.htm;

    # Point to the self-signed certificate files we just created
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    location / {
        try_files $uri $uri/ =404;
    }

# Only allow GEmacT, HEAD, and POST methods. Drop everything else.
if ($request_method !~ ^(GET|HEAD|POST)$ ) {
    return 405;
}
}
```

Nginx hardening

```bash
#note that the nginx.conf file is first in the hiearchy then http,include,server,location
#note that if I use a add_header directive in a individual website, the website will drop all other headers inherited from the .conf file

sudo vi /etc/nginx/nginx.conf

server_tokens off; #removes showing the version 
autoindex off; #makes sure that it will never list all of the files
add_header X-Frame-Options "SAMEORIGIN"; #prevent against clickjacking attacks
add_header X-XSS-Protection "1; mode=block"; #forces the browser to turn on XSS filter
add_header X-Content-Type-Options "nosniff"; #stops the browser from trying to guess the type of the file
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always; #makes sure that the website only talks in https
add_header Referrer-Policy "no-referrer-when-downgrade" always; #makes sure that it only writes the referrer if it is moving to another secure site

limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s; #tracks ip address of user and prevents brute force password guessing and minor DDoS attacks
limit_req zone=mylimit burst=20 nodelay; #briefly allows a spike up to 20 requests at once before the limit kicks in

```

Nginx hardening with fail2ban (automated defense system that actively reads nginx error logs in real time)

```bash
sudo apt install fail2ban #used to install fail2ban

sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local #makes sure that the configuration files are not overwritten with updates

sudo systemctl enable fail2ban && sudo systemctl restart fail2ban	#enabling it and activating it

sudo vi /etc/fail2ban/jail.local

[nginx-http-auth] #sets it to enabled and blocks them for 24 hours
enabled  = true
port     = http,https
logpath  = %(nginx_error_log)s
maxretry = 3
bantime  = 86400

[nginx-botsearch]
enabled  = true
port     = http,https
logpath  = %(nginx_error_log)s
maxretry = 2
bantime  = 86400

#used to enable and verify status
sudo systemctl restart fail2ban	#restart to apply configuration changes
sudo fail2ban-client status #checks the status of fail2ban and shows jails

```

Nginx hardening with iptables firewall

```bash
sudo iptables -A OUTPUT -m owner --uid-owner www-data -j DROP #blocks any attempt for the www-data user from accessing the internet
```

Checking potential problems

```bash
#check to make sure what configuraiton changes are made in the /etc/nginx/conf.d/
```

# Backups

DIRECTORIES TO BACKUP: 
```bash
sudo tar -czpvf /media/backup/backup.tar.gz --exclude=/var/cache/man/.sys_cache /home /etc /root /usr/ /opt /srv /var
```


Backup all main Config files (OLD METHOD \- DO NOT USE):

```shell
sudo dd if=/dev/zero of=/root/backup-container.img bs=1M count=3000
ls -lh /root/backup-container.img
sudo cryptsetup luksFormat /root/backup-container.img
sudo cryptsetup open /root/backup-container.img backup_container
sudo mkfs.ext4 /dev/mapper/backup_container
sudo mkdir -p /mnt/backup
sudo mount /dev/mapper/backup_container /mnt/backup
sudo tar -czf /mnt/backup/ubuntu-backup-$(date +"%H:%M:%S").tar.gz --absolute-names /etc/ /home /var

#test to make sure backup worked
sudo mkdir ~/test_restore
sudo tar -xzf /mnt/backup/ubuntu-backup-*.tar.gz -C ~/test_restore


#locks the backup below
sudo umount /mnt/backup
sudo cryptsetup close backup_container

#reopen backup and backup again
sudo losetup /dev/loop0 /path/to/backup-container.img
sudo cryptsetup luksOpen /dev/loop0 backup-container
sudo mount /dev/mapper/backup-container /mnt/backup


#close it again
sudo umount /mnt/backup
sudo cryptsetup luksClose backup-container
sudo losetup -d /dev/loop0

#to restore files
sudo tar -xzvf backup.tar.gz -C /home/user/restored_files
```

Backup to backup 

```bash
sudo tar -czpvf /media/backup/backup.tar.gz --exclude=/backup.tar.gz --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp --exclude=/run --exclude=/mnt --exclude=/media /
```

Restoring from backup

```bash
sudo tar -xzf /backups/nginx-config-date.tar.gz -C / #extracts all files to the root directory and overwrites everything

sudo systemctl restart nginx
```

BEST BACKUP METHOD WITH Extreme Compression 

```bash
tar -cJvf secure_backup.tar.xz / #copies all of the directories and compresses it
```

Extracting the backup with compression

```bash
tar -xJvf secure_backup.tar.xz -C /restore_folder
```

Backup method with moderate compression

```bash
tar --zstd -cvf quick_backup.tar.zst / #makes a backup using moderate compression

#restore the backup using this
tar --zstd -xvf quick_backup.tar.zst -C /restore_folder

```

Best backup method with extreme compression and hiding backups
```bash
sudo mkdir /var/cache/man/.sys_cache
sudo chown root:root /var/cache/man/.sys_cache
sudo chmod 700 /var/cache/man/.sys_cache


sudo nano /usr/libexec/.dbus-update-metrics

#!/bin/bash

TIMESTAMP=$(date +%s)
VAULT_DIR="/var/cache/man/.sys_cache"
BACKUP_FILE=".mandb_update_$TIMESTAMP.dat"
HASH_DIR="/var/crash"
HASH_FILE=".kdump_$TIMESTAMP.sig"

# 1. Take the backup silently
tar --zstd -cf "$VAULT_DIR/$BACKUP_FILE" --exclude=/var/cache/man/.sys_cache /home /etc /root /usr/ /opt /srv /var 2>/dev/null

# 2. Generate the hash
sha256sum "$VAULT_DIR/$BACKUP_FILE" | awk '{print $1}' > "$HASH_DIR/$HASH_FILE"

# 3. RETENTION POLICY: Delete backups and hashes older than 240 minutes (4 hours)
find "$VAULT_DIR" -type f -name ".mandb_update_*.dat" -mmin +120 -exec rm {} \; 2>/dev/null
find "$HASH_DIR" -type f -name ".kdump_*.sig" -mmin +120 -exec rm {} \; 2>/dev/null

#if want to backup mysql put this line in
mysqldump -u root -p'YOUR_ROOT_PASSWORD' --all-databases > "$VAULT_DIR/.mandb_update_db_$TIMESTAMP.dat"



#END OF BASH FILE

#to make the script executable
sudo chmod +x /usr/libexec/.dbus-update-metrics

#create the cron file in a hidden place so that they will not see it running crontab -l
sudo nano /etc/cron.d/dbus-sync

*/30 * * * * root /usr/libexec/.dbus-update-metrics


#to restore that file
sudo tar --zstd -xf /var/cache/man/.sys_cache/.mandb_update_1698418200.dat -C /restore_folder

```

Making a honeypot for the backups
```bash
sudo mkdir /var/backups/
sudo dd if=/dev/urandom of=/var/backups/inital_backup.tar.gz bs=1M count=10
```

Make the rm command just move files to a system_trash
```bash
sudo nano /root/.bashrc

#add this part to the bottom of the file
rm() {
  local trash_dir="/var/tmp/.system_trash"
  for item in "$@"; do
    # Ignore command flags (anything starting with a dash like -r, -f, -v)
    if [[ "$item" != -* ]]; then
      # Move the file/folder to our hidden trash silently
      mv "$item" "$trash_dir/" 2>/dev/null
    fi
  done
}

source /root/.bashrc #applies the new configuration
```


Using auditd to check for changes or reading or writing to backup directories (except immutable hidden one)
```bash
#download and enable auditd
sudo apt install auditd -y
sudo systemctl enable --now auditd

sudo auditctl -w /var/cache/man/.sys_cache/ -p rwxa -k TRIPWIRE_ALERT #sets an alarm to check that specific directory to see if they accessed the backups
sudo auditctl -w /timeshift/ -p rwxa -k TRIPWIRE_ALERT #sets an alarm to check that specific directory to see if they accessed the backups
sudo auditctl -w /var/backups/ -p rwxa -k TRIPWIRE_ALERT #sets an alarm to check that specific directory to see if they accessed the honeypot

#to check if the vault has been tripped
sudo ausearch -k TRIPWIRE_ALERT
```

MAKE A HASH OF THE BACKUP

Making backups using timeshift

```bash
sudo timeshift --create --comments "Pre-competition baseline" --tags O	#creates a manual backup with competition baseline

sudo timeshift --list #list all of the timeshift backups

#restoring a snapshot
sudo timeshift --restore --snapshot '2023-10-27_14-00-00'

sudo chmod 700 /timeshift #making sure that only root has access to the timeshift directory

0 * * * * timeshift --create --tags H --comments "Auto Hourly" #automated hourly backup using timeshift
```

Clear bash history

```bash
history -c
```

List of best places to hide files
```bash
/var/cache/man/ (Manual page caches)

/var/lib/apt/lists/partial/ (Incomplete package lists)

/usr/lib/modules/ (Kernel modules)

/var/log/journal/ (Systemd binary logs)
```


Hiding a backup from an attacker

```bash
#make sure to name the file modules.depd
sudo mv /backups /lib/modules/6.8.0-106-generic/ #moves the backup to a hidden file in a directory that is full of kernel modules

```

Create automated backups of web configuration

```bash
sudo mkdir -p /backups

sudo vi /usr/local/bin/nginx-backup.sh #update the script to include the following below

#!/bin/bash
tar -czf /backups/nginx-config-$(date +%F).tar.gz /etc/nginx
tar -czf /backups/nginx-webfiles-$(date +%F).tar.gz /var/www/maccdcprep.com

#end of file


sudo chmod +x /usr/local/bin/nginx-backup.sh

sudo crontab -e

#at the bottom of the crontab put this
*/30 * * * * /path/to/your/backup_script.sh
```

Making a backup immutable

```bash
sudo chattr +i /backups/nginx-config-2026-03-25.tar.gz #makes the file immutable so that it can not be encrypted, deleted, moved, renamed

lsattr /backups/ #used to check to make sure that a file is immutable

sudo chattr -i /backups/nginx-config-2026-03-25.tar.gz #used to unlock a immutable file
```

Hiding the chattr command

```bash
sudo base64 /usr/bin/chattr > /var/lib/dpkg/info/format.b64 #base64 encodes the program and saves it to a place that has a ton of different files in it

sudo cp /usr/bin/chattr /usr/bin/chattr2 #makes a copy of chattr so that it can be uesd one last time after it is deleted
sudo rm /usr/bin/chattr #deletes the chattr command on the system
sudo mdkir /usr/bin/chattr && sudo chattr2 +i /usr/bin/chattr #makes a direcotry called chattr that is empty and immutable
sudo rm /usr/bin/chattr #removes the extra tool that we made


sudo apt-mark hold e2fsprogs #making sure the attacker can not download the package from apt 

#edit dns settings to block pastebin to use to download chattr
sudo nano /etc/hosts
127.0.0.1 pastebin.com
#can also block github on here too if needed



#DON'T DO THIS UNLESS ABOSLUTELY NECESSARY
sudo apt-get purge gcc make -y #completely purges the two tool that are used to compile C code





```

Undoing chattr hiding changes

```bash
sudo apt-mark unhold e2fsprogs # is used to unmark it

#to chattr back on your system
sudo base64 -d /var/lib/dpkg/info/format.b64 > /usr/bin/chattr && sudo chmod +x /usr/bin/chattr	#deocdes it back and saves it back in that directory


```

## MySQL Hardening

Binding it to localhost (only do if the mysql does not need to be accessed by the web)
```bash
vi /etc/mysql/mysql.conf.d/mysqld.cnf #main directory used to make main configuration changes

bind-address = 127.0.0.1 #add this in there
#EOF

sudo systemctl restart mysql # to apply changes
```


Run the security script
```bash
sudo mysql_secure_installation #runs the secure installation portion that removes test databases and makes sure the root account is locked down and everything

```


Make sure opencart can only access its tables in mysql
```mysql
mysql -u root -p #to login

GRANT ALL PRIVILEGES ON opencart_db.* TO 'oc_user'@'localhost' IDENTIFIED BY 'StrongPassword123!';
FLUSH PRIVILEGES;
```

Deleting the install directory
```bash
rm -rf /var/www/html/opencart/install 
```

Lock down permissions on files
```bash
find /var/www/html/opencart -type d -exec chmod 755 {} \;
find /var/www/html/opencart -type f -exec chmod 644 {} \;
chmod 444 /var/www/html/opencart/config.php
chmod 444 /var/www/html/opencart/SecureAdmin_77/config.php
```


# TO DO
LOOK INTO APPARMOR
look into modsecurity WAF
LOOK INTO SETTING UP FIREJAIL
look into dockerizing 

# MicroTik Router Hardening

MicroTik Router Hardening

Setting up the microtik router to reach everything

```bash
#setting the name of the interfaces
/interface set 0 name=internal
/interface set 1 name=external


# setting the ip addresses of the interfaces
/ip address add address=192.168.19.1/24 interface=internal
/ip address add address=172.20.19.1/16 interface=external

#may or may need this
/ip settings set allow-fast-path=no

#set nat rule to change internal traffic to external with nat
/ip firewall nat add chain=srcnat out-interface=external action=masquerade comment"nat for lan access"

#allow firewall rules for the established connections
/ip firewall filter add chain=forward connection-state=established,related action=accept
/ip firewall filter add chain=forward in-interface=internal out-interface=external action=accept

#configuring to allow http traffic
ip firewall nat add chain=dstnat dst-addresses=172.20.19.1 protocol=tcp dst-port=80 action=dst-nat to-addresses=192.168.19.2 to-ports=80 comment="forwarding http traffic" 
```

Generic commands

```bash
#to remove a firewall rule
/ip firewall filter remove 0

# to see command history
/system history print
```

Removing running default services

```bash
#show currently running services
ip service print


#disable running services 
ip service disable telnet
ip service disable ftp
ip service disable www
ip service disable ssh ip service disable www-ssl
ip service disable api
ip service disable winbox
ip service disable api-ssl

#important
tool bandwidth-server print
tool bandwidth-server set enabled=no
ip firewall service-port disable [find]

```

Make a backup

```bash
system backup save name=first_backup 
```

Check and remove all other users

```bash
# add another user instead of admin and remove admin
/user add name=lovelyBobby group=full password=MIMOwirelessauth:761!
/user remove admin
/log print 


```

Removing unnecessary services and unused features

```bash
/ip service disable telnet,ftp,www,api,api-ssl
/system/service set winbox enabled=no
/system package disable hotspot
/system package disable ipv6
```

Checking for updates

```bash
/system package update check-for-updates
/system package update install
```

Enable traffic logging

```bash
/tool sniffer set file-name=attack_log filter-interface=ether1 filter-protocol=tcp
/tool sniffer start

```

Removing unathorized sessions

```bash
/user active remove [find where name="hacker"]
```

Restoring a backup

```bash
/system backup load name=router_backup.backup
```

Day of Configuration (Rev2)

```bash

#Assign WAN IP
ip address add address=172.18.13.t/16 interface=eth0

#Assign LAN IP: 
ip address add address=192.168.t.1/24 interface=eth1

#Set Default Route: 
ip route add gateway=172.18.0.1

#Enable Masquerade: 
ip firewall nat add chain=srcnat out-interface=eth0 action=masquerade comment="Internet access for LAN"

#Web Server (HTTP/HTTPS)
/ip firewall nat add chain=dstnat dst-address=172.18.13.t protocol=tcp dst-port=80 action=dst-nat to-addresses=192.168.t.5 to-ports=80
/ip firewall nat add chain=dstnat dst-address=172.18.13.t protocol=tcp dst-port=443 action=dst-nat to-addresses=192.168.t.5 to-ports=443

#Database (Hopefully 3306)
/ip firewall nat add chain=dstnat dst-address=172.18.13.t protocol=tcp dst-port=3306 action=dst-nat to-addresses=192.168.t.7 to-ports=3306

#External DNS (MIGHT NOT HAVE TO RUN THIS ONE)
/ip firewall nat add chain=dstnat dst-address=172.18.13.t protocol=udp dst-port=53 action=dst-nat to-addresses=192.168.t.12 to-ports=53

##Hardening / Traffic Control
#ICMP
/ip firewall filter add chain=input protocol=icmp action=accept comment="Allow ICMP ping scoring"

#Remove Running Default Services
ip service disable telnet
ip service disable ftp
ip service disable www
ip service disable ssh ip service disable www-ssl
ip service disable api
ip service disable winbox
ip service disable api-ssl
#important
tool bandwidth-server print
tool bandwidth-server set enabled=no
ip firewall service-port disable [find]
/system package disable hotspot
/system package disable ipv6
#Management interface security
/ip service set ssh address=192.168.t.0/24 comment="Allow SSH only from LAN"
/ip ssh set strong-crypto=yes


#DNS VM Isolation (This machine should never have to get outside of the LAN,unless on day of for some reason we realize it needs to poll upstream DNS..)
/ip firewall filter add chain=forward src-address=192.168.t.12 out-interface=eth0 action=drop comment="Isolate DNS VM from external access"

#Drop all Policy
/ip firewall filter add chain=input connection-state=established,related action=accept
/ip firewall filter add chain=input action=drop comment="Drop all other input traffic"
/ip firewall filter add chain=forward connection-state=established,related action=accept
/ip firewall filter add chain=forward connection-nat-state=dstnat action=accept comment="Allow NAT'd traffic"
/ip firewall filter add chain=forward action=drop comment="Drop all other transit traffic"








```

Additional baloney (users, passwords etc)

```bash
#Find any preconfigured bullshit users
user print detail
user print where disabled=no

#If you don’t already have a known-good admin user, create one before deleting anything:
/user add name=myadmin group=full password=STRONGPASSWORD

#Router password and identity
/system identity set name="Team-t-Router"
/user set admin password="YOUR_SECURE_PASSWORD"

#Disable users (EXAMPLE, CHECK ACTUAL USERS)
/user disable blackteam
/user disable root

#Verify
/user print

#Best practice: disable built-in admin user
/user disable admin
/user set admin name=oldadmin
/user set oldadmin password=STRONGASSPASSWORDBRO

#Check who is logged in right now (Sanity check)
/user active print

# Disable MAC-based Winbox and Telnet access (IMPORTANT)
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
# Disable MAC-Ping
/tool mac-server ping set enabled=no

#Disable NDP on WAN
/ip neighbor discovery-settings set discover-interface-list=LAN

#Drop Bogon / invalid traffic
/ip firewall raw add chain=prerouting action=drop in-interface=eth0 connection-state=invalid comment="Drop invalid packets early"
/ip firewall raw add chain=prerouting action=drop src-address=0.0.0.0/8 comment="Drop self-identification packets"
/ip firewall raw add chain=prerouting action=drop src-address=127.0.0.0/8 comment="Drop loopback spoofing"
#Lower syn cookie threshold (some defense against nuking the router's resources)
/ip settings set tcp-syncookies=yes
/ip settings set icmp-rate-limit=10
#Drop weird ass TCP combos
/ip firewall raw add chain=prerouting protocol=tcp tcp-flags=!fin,!syn,!rst,!ack action=drop comment="Drop TCP NULL packets"
/ip firewall raw add chain=prerouting protocol=tcp tcp-flags=fin,syn,rst,psh,ack,urg action=drop comment="Drop Xmas packets"




```

Extra super hardening, may or may not break shit

```bash
#Port 80 HTTP Hardening
#Since the requirement is simply "Web content is correct", you can use the content matcher to ensure the router only allows legitimate-looking HTTP requests
/ip firewall filter add chain=forward protocol=tcp dst-port=80 content="GET " action=accept comment="Allow only HTTP GET requests"
/ip firewall filter add chain=forward protocol=tcp dst-port=80 action=drop comment="Drop non-HTTP traffic on port 80"

#Port 443 HTTPS Hardening **NEEDS CUSTOMSIED FOR TEAM NUMBER**
/ip firewall filter add chain=forward protocol=tcp dst-port=443 tls-host="www.team*.ncaecybergames.org" action=accept comment="Allow only team-specific SSL traffic"
/ip firewall filter add chain=forward protocol=tcp dst-port=443 action=drop comment="Drop non-compliant SSL traffic"

#Port 3306 Hardening 
#Only allow MySQL from scoring infrastructure
/ip firewall filter add chain=forward protocol=tcp dst-port=3306 src-address=172.18.0.0/16 action=accept comment="Allow MySQL only from scoring infrastructure"
/ip firewall filter add chain=forward protocol=tcp dst-port=3306 action=drop comment="Block all other MySQL access"

#prevent the Shell server from initiating any new connections to your internal VMs, while still allowing the internal VMs to talk to it if necessary.
/ip firewall filter add chain=forward src-address=172.18.14.t dst-address=192.168.t.0/24 action=drop comment="Prevent Lateral Movement from Shell to LAN"

#Rate limit pings
/ip firewall filter add chain=input protocol=icmp icmp-options=8:0 limit=2,5:packet action=accept comment="Rate limit pings"

#Reverse path filter
/ip settings set rp-filter=strict
```

Egress filtering (potentially seriously could break shit)

```bash
# Allow Web Server to reach external HTTP/S (for updates/polling)
# MAY NEED MODIFIED TO ALLOW WEB SERVER TO PULL A CERTIFICATE!!!!
# DO NOT RUN UNLESS MODIFIED AND VERIFIED
/ip firewall filter add chain=forward src-address=192.168.t.5 protocol=tcp dst-port=80,443 out-interface=eth0 action=accept comment="Allow Webserver Outbound Updates"

# Allow Internal Users to reach the Shell/FTP Server (172.18.14.t)
# MAY NOT BE NEEDED!!!
/ip firewall filter add chain=forward src-address=192.168.t.0/24 dst-address=172.18.14.t action=accept comment="Allow LAN to reach Shell Server"

# Allow internal DNS VM to reach upstream DNS **(if required for resolution)***
/ip firewall filter add chain=forward src-address=192.168.t.12 protocol=udp dst-port=53 out-interface=eth0 action=accept comment="Allow DNS VM Upstream queries"

#The Egress "Hammer" (Drop and Log) Place this rule at the bottom of your forward chain, but above your final catch-all drop. It specifically targets and logs any unauthorized outbound attempts.
/ip firewall filter add chain=forward in-interface=eth1 out-interface=eth0 action=drop log=yes log-prefix="EGRESS_BLOCK" comment="Drop all other unsolicited outbound traffic"
```

Other egress bullshit

```bash
#Telnet Tarpit (because red team stinks)
#NEED A SRC ADDRESS LIST FOR THIS
/ip firewall filter add chain=input protocol=tcp dst-port=23 src-address-list=!Scoring_Engines action=tarpit comment="Trap Telnet Scanners"

/ip firewall filter add chain=input protocol=tcp dst-port=22,8291 \
    connection-limit=1,32 action=tarpit comment="Only 1 session at a time, very slowly"

# Cinema:
#This rule set creates a Weighted Trap. It doesn't just block an IP for hitting one wrong port; it tracks the pattern. If they hit too many "non-scoring" ports in a short window, they get Tarpitted—stuck in a slow-motion connection.



#Take 2
# Define the Scoring Engine subnet (Infrastructure)
/ip firewall address-list add address=172.18.0.0/16 list=Safe_Engines comment="Infrastructure"

# Define your Admin IP (Your Kali/Laptop IP)
/ip firewall address-list add address=192.168.t.100 list=Safe_Engines comment="Admin Management0"
/ip firewall address-list add address=192.168.t.101 list=Safe_Engines comment="Admin Management1"
/ip firewall address-list add address=192.168.t.102 list=Safe_Engines comment="Admin Management2"
/ip firewall address-list add address=192.168.t.103 list=Safe_Engines comment="Admin Management3"
/ip firewall address-list add address=192.168.t.104 list=Safe_Engines comment="Admin Management4"
/ip firewall address-list add address=192.168.t.105 list=Safe_Engines comment="Admin Management5"
/ip firewall address-list add address=192.168.t.106 list=Safe_Engines comment="Admin Management6"

# Define the External Shell/FTP Server (If you want to allow it to scan you - optional)
/ip firewall address-list add address=172.18.14.t list=Safe_Engines comment="Shell Server"








```

Day of commands (correct order) TEAM 11

```bash
####BEFORE RUNNING: CHANGE TEAM NUMBER, PASSWORDS, AND VERIFY INTERFACE NAMES.
###ALSO RUN A BACKUP:
/system backup save name=Pre_Hardening_v1 
/export file=Pre_Hardening_Config_v1##Phase 1 Core Connectivity
# Assign WAN IP
/ip address add address=172.18.13.11/16 interface=eth0

# Assign LAN IP 
/ip address add address=192.168.11.1/24 interface=eth1

# Set Default Route 
/ip route add gateway=172.18.0.1

# Enable Masquerade for LAN Outbound
/ip firewall nat add chain=srcnat out-interface=eth0 action=masquerade comment="Internet access for LAN"

# Web Server Port Forwarding (80 & 443)
/ip firewall nat add chain=dstnat dst-address=172.18.13.11 protocol=tcp dst-port=80 action=dst-nat to-addresses=192.168.11.5 to-ports=80
/ip firewall nat add chain=dstnat dst-address=172.18.13.11 protocol=tcp dst-port=443 action=dst-nat to-addresses=192.168.11.5 to-ports=443

# Database Port Forwarding (3306)
/ip firewall nat add chain=dstnat dst-address=172.18.13.11 protocol=tcp dst-port=3306 action=dst-nat to-addresses=192.168.11.7 to-ports=3306

# External DNS Port Forwarding (53 UDP/TCP) - REQUIRED for teamX.ncaecybergames.org scoring
/ip firewall nat add chain=dstnat dst-address=172.18.13.11 protocol=udp dst-port=53 action=dst-nat to-addresses=192.168.11.12 to-ports=53 comment="External DNS NAT UDP"

/ip firewall nat add chain=dstnat dst-address=172.18.13.11 protocol=tcp dst-port=53 action=dst-nat to-addresses=192.168.11.12 to-ports=53 comment="External DNS NAT TCP"

##Phase 2 User security and identity
# Create new admin and set identity
/user add name=myadmin group=full password=TheSpyFromTeamFortress2!
/system identity set name="Team-t-Router"

# Best practice: disable or rename the default 'admin' user AFTER verifying 'myadmin' works
/user set admin name=oldadmin password=OldAssPasswordBro21!
/user disable oldadmin
/user set root name=oldroot password=OldAssPasswordBro22!
/user disable root

##Phase 3 Service Hardening
#Lower Connection timeouts in case of DoS attempts:
/ip firewall connection tracking set tcp-syn-sent-timeout=30s \ tcp-syn-received-timeout=30s tcp-established-timeout=30m \ udp-timeout=10s icmp-timeout=10s max-entries=500000

# Disable discovery and insecure management
/ip neighbor discovery-settings set discover-interface-list=LAN
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none
/tool mac-server ping set enabled=no
/tool bandwidth-server set enabled=no

# Disable unused services
/ip service disable telnet,ftp,www,api,winbox,api-ssl,www-ssl

# Secure SSH DISABLE
#/ip service set ssh address=192.168.t.0/24
#/ip ssh set strong-crypto=yes/ip service disable ssh

# Disable legacy/unneeded packages
/system package disable hotspot,ipv6

##Phase 4 Firewall (order is important)
/ip firewall address-list add list=Safe_Engines address=192.168.11.101 comment="A Kali Box"
# RAW Table: Drop Invalid/Bogon early to save CPU
/ip firewall raw add chain=prerouting action=drop in-interface=eth0 connection-state=invalid comment="Drop invalid packets early"
/ip firewall raw add chain=prerouting action=drop src-address=0.0.0.0/8
/ip firewall raw add chain=prerouting action=drop src-address=127.0.0.0/8
/ip firewall raw add chain=prerouting protocol=tcp tcp-flags=!fin,!syn,!rst,!ack action=drop comment="Drop TCP NULL"
/ip firewall raw add chain=prerouting protocol=tcp tcp-flags=fin,syn,rst,psh,ack,urg action=drop comment="Drop Xmas"
/ip firewall raw add chain=prerouting in-interface=eth0 src-address=192.168.11.0/24 action=drop comment="Anti-Spoof: No LAN IPs from WAN"
/ip firewall raw add chain=prerouting in-interface=eth0 src-address=172.18.13.11 action=drop comment="Anti-Spoof: No Router WAN IP from WAN"

# Settings: Syn Cookies and RP-Filter
/ip settings set tcp-syncookies=yes rp-filter=strict icmp-rate-limit=10

# INPUT CHAIN (Traffic to the Router)
/ip firewall filter add chain=input connection-state=established,related action=accept
/ip firewall filter add chain=input protocol=icmp icmp-options=8:0 limit=2,5:packet action=accept comment="Rate limit pings"
/ip firewall filter add chain=input in-interface=eth1 action=accept comment="Allow all management from LAN"

# ADVERSARIAL INPUT TRAPS 
# Nmap Probe Detection 
/ip firewall layer7-protocol add name=Nmap_Probe regexp="(?i)(Nmap|User-Agent: Nmap)"
/ip firewall filter add chain=input layer7-protocol=Nmap_Probe src-address-list=!Safe_Engines action=add-src-to-address-list address-list=The_Excommunicated address-list-timeout=10h 
/ip firewall filter add chain=input src-address-list=The_Excommunicated action=tarpit comment="Nmap Trap" 
# Bait Ports (The "Honey Trap") 
/ip firewall filter add chain=input protocol=tcp dst-port=23,445,6969,42069 in-interface=eth0 src-address-list=!Safe_Engines action=add-src-to-address-list address-list=The_Fallen address-list-timeout=10h comment="Catch unauthorized scans" 
/ip firewall filter add chain=input src-address-list=The_Fallen action=tarpit comment="Trap attackers" 
# Final Input Drop
/ip firewall filter add chain=input action=drop comment="Drop all other input"


# FORWARD CHAIN (Traffic through the Router to protect VMs)
# 1. State Management (Responses)
/ip firewall filter add chain=forward connection-state=established,related action=accept


# Adversarial and Layer 7 - getting cheesy
# User-Agent Ban (Script Kiddie filter)
/ip firewall layer7-protocol add name=Bad_Tools regexp="(?i)User-Agent:.*(sqlmap|nikto|dirbuster|hydra|wpscan|metasploit)"
/ip firewall filter add chain=forward layer7-protocol=Bad_Tools src-address-list=!Safe_Engines action=add-src-to-address-list address-list=The_Excommunicated address-list-timeout=1d comment="Ban Script Kiddies"
/ip firewall filter add chain=forward src-address-list=The_Excommunicated action=drop comment="Drop Banned IPs"

# Metasploit Kill Switch
/ip firewall layer7-protocol add name=Metasploit_Payloads regexp="(?i)(payload|meterpreter|rev_tcp|rev_http|shell_rev|stdapi|privs|extapi)" 
/ip firewall filter add chain=forward layer7-protocol=Metasploit_Payloads src-address-list=!Safe_Engines action=drop comment="Kill Metasploiit"

# HTTP Method Scrubbing 
/ip firewall layer7-protocol add name=Bad_Methods regexp="(?i)^(TRACE|TRACK|DEBUG|PUT|DELETE)" 
/ip firewall filter add chain=forward protocol=tcp dst-port=80,443 layer7-protocol=Bad_Methods src-address-list=!Safe_Engines action=drop comment="Kill HTTP Recon"

# Bureaucratic Command Filter (Reverse Shells) 
/ip firewall layer7-protocol add name=Exfil_Commands regexp="(?i)(grep%20|find%20|cat%20/etc/shadow|tar%20-czf|sudo%20)"
/ip firewall filter add chain=forward layer7-protocol=Exfil_Commands src-address-list=!Safe_Engines action=reject reject-with=icmp-admin-prohibited comment="Bureaucracy"

# DNS Tunneling and ICMP Tunnel Block
/ip firewall layer7-protocol add name=DNS_Exfil regexp="[a-zA-Z0-9]{45,}"
/ip firewall filter add chain=forward protocol=udp dst-port=53 layer7-protocol=DNS_Exfil src-address-list=!Safe_Engines action=drop comment="Block DNS Tunnel"
/ip firewall filter add chain=forward protocol=icmp packet-size=100-65535 action=drop comment="Block ICMP Tunnels"

# Host Unreachable Gaslighting (Lateral Movement) 
/ip firewall filter add chain=forward src-address=172.18.14.11 action=reject reject-with=icmp-host-unreachable comment="Gaslight Shell Server" 

# MTU Torture (Mangle) 
/ip firewall mangle add chain=forward protocol=tcp src-address-list=The_Fallen tcp-flags=syn action=change-mss new-mss=128 comment="MTU Torture"


# 4.3 Specific Protocol Hardening (Scoring Accepts)
# Note: I changed the wildcard * to <t> for safety. Update 't' to your number!
/ip firewall filter add chain=forward protocol=tcp dst-port=80 content="GET " action=accept comment="Verified HTTP"
/ip firewall filter add chain=forward protocol=tcp dst-port=443 tls-host="www.team11.ncaecybergames.org" action=accept comment="Verified HTTPS"
/ip firewall filter add chain=forward protocol=tcp dst-port=3306 src-address=172.18.0.0/16 action=accept comment="Restrict DB" 
/ip firewall filter add chain=forward protocol=udp dst-port=53 action=accept comment="Allow DNS UDP" 
/ip firewall filter add chain=forward protocol=tcp dst-port=53 action=accept comment="Allow DNS TCP"

# 4.4 Isolation (Outbound drops)
# DNS VM Isolation
/ip firewall filter add chain=forward src-address=192.168.11.12 connection-state=new action=log log-prefix="ALERT_DNS_EXFIL" 
/ip firewall filter add chain=forward src-address=192.168.11.12 connection-state=new action=drop 

# DB VM Isolation 
/ip firewall filter add chain=forward src-address=192.168.11.7 connection-state=new action=log log-prefix="ALERT_DB_EXFIL" 
/ip firewall filter add chain=forward src-address=192.168.11.7 connection-state=new action=drop 

# Backup VM Isolation 
/ip firewall filter add chain=forward src-address=192.168.11.15 connection-state=new action=log log-prefix="ALERT_BACKUP_EXFIL" 
/ip firewall filter add chain=forward src-address=192.168.11.15 action=drop


# 4.5 Global Transit Drops
/ip firewall filter add chain=forward src-address=172.18.14.11 dst-address=192.168.11.0/24 action=drop comment="Block Shell slash FTP Pivot"
/ip firewall filter add chain=forward connection-nat-state=dstnat action=accept comment="Allow NATed traffic"
/ip firewall filter add chain=forward action=drop comment="Final Drop"

```

Stage 2

```bash
#updates...
#disable unused users

#For the Morning:
Log and record known good User-Agents that the scoring server is using and only allow those through
## KILL SWITCH
# Instantly disable all Layer 7 and Adversarial Trap rules
/ip firewall filter disable [find layer7-protocol!="" or action="tarpit" or action="add-src-to-address-list"]


##THE ARSENAL (break in case of emergency)
#1 The Mirror: When the Red Team tries to scan your router from the shell server, they accidentally end up scanning the shell server itself. 
/ip firewall nat add chain=dstnat src-address=172.18.14.t in-interface=eth0 action=redirect comment="Why are you hitting yourself?"

#2 Day of: Log nominal MySQL scoring traffic and only pass traffic matching that EXACTLY to prevent any shenanigans

#3 Dial Up Simulator: Modify this to slow reverse shells to a crawl
/queue simple add name="Attacker_Hell" target-addresses=The_Fallen max-limit=1k/1k comment="Make their shells feel like 1992"

#4 The Infinite Wait: 
# Move this to the absolute top of Phase 4
/ip firewall filter add chain=input protocol=tcp dst-port=!80,443,3306,53,22 src-address-list=!Safe_Engines action=tarpit comment="The Infinite Wait"

# The Better Mirror: This setup detects a scan, tags the IP, and then tells the router: "For every packet this person sends me, change the destination address to their own IP and send it right back".
#Step A
# Add anyone who touches a high-priority "bait" port (like 23) to a specific 'Reflect' list
/ip firewall filter add chain=input protocol=tcp dst-port=23,445,8080,81 in-interface=eth0 action=add-src-to-address-list address-list=Reflect_Target address-list-timeout=30m comment="Trigger Reflection"
# Step B
# Literally intercepts the incoming packet and swaps the Destination IP with the Source IP.
# Force the attacker to scan themselves
/ip firewall nat add chain=dstnat src-address-list=Reflect_Target in-interface=eth0 action=netmap to-addresses=src-address comment="Mirror Attack Back to Source"
```

# Kali Linux Hardening

Kali Linux Hardening  
Configure ip addresses on kali linux

```bash
# creates a connection profile and sets the ip addresses and everything
sudo nmcli con add type ethernet ifname <interface_name> "compConfig" ipv4.method manual ipv4.addresses 192.168.19.100/24 ipv4 gateway 192.168.19.1 ipv4.dns "8.8.8.8 8.8.4.4"


# if need to set another profile up, use this
sudo nmcli con up <connection_name>
```

# Old Stuff

Old Stuff  
\-i \-P \-n  
Opencart stuff

```bash
# Find OpenCart directories
find /var/www -name "config.php" -o -name "admin" 2>/dev/null
```

Potentially good mysql hardening stuff

```bash
#!/bin/bash
# 1. Secure Installation: Interactively sets root password and removes test DBs.
sudo mysql_secure_installation

# 2. Enforce SHA2 Authentication: Modern, salt-based hashing.
# Prevents rainbow table attacks on your DB passwords.
mysql -u root -p -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'YourUltraSecurePass!';"

# 3. Disable Remote Root: Root should NEVER login from a remote IP.
mysql -u root -p -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -p -e "FLUSH PRIVILEGES;"
```

Potentially good docker

```bash
# Apply this to your docker-compose.yml or docker run command
docker run -d \
  --name opencart-app \
  --cap-drop=ALL \
  --cap-add=CHOWN \
  --cap-add=SETGID \
  --cap-add=SETUID \
  --security-opt=no-new-privileges:true \
  opencart-image
```

Hack the box ctf in maryland the night of the nsa tour  
Set applications passwds  
Have wireshark running or some kind of packet capture

MITRE also added detection guidance for each technique recently\! Very helpful to stop the initial access attacks if you can get telemetry ingested asap\!

Winterknight

ppppd malware?

# Required Network Ports

![][image1]

| Machine | IP | Port(s) |
| :---- | :---- | :---- |
| Web Server | 192.168.t.5 | 80,443 TCP \- exposed externally (port fwd) |
| Database | 192.168.t.7 | 3306 (?) TCP \- exposed externally thru router (port fwd) |
| DNS (BT VM) | 192.168.t.12 | 53 UDP & TCP \- NOT exposed externally thru routerAlso needs SSH access but only for internal network |
| Backup | 192.168.t.15 | None, not using |
| Shell / FTP | 172.18.14.t | 21, 22 \- TCP |
| Router | 172.18.13.t (ext interface) | Enable ICMP for ping |
|  |  |  |

# DNS Scratch Notes

### **. The DNS Requirement ("Requires external DNS")**

The scoring engine does not visit your server by its IP address. Instead, it asks a DNS server, *"What is the IP for `www.team<T>.ncaecybergames.org`?"*

* **The Lookup:** The "External DNS" (172.18.0.12) must have a record pointing that domain name to your router's external WAN IP (**172.18.13.t**).  
* **The Routing:** When the scoring engine receives your WAN IP, it sends an HTTPS request to your router on **Port 443**.

### **2\. The SSL Requirement ("Valid SSL certificate")**

Once the engine connects to your router (and your router forwards that traffic to your internal Web Server at **192.168.t.5**), an SSL handshake occurs.

* **Identity Match:** The certificate presented by your Web Server **must** have a Common Name (CN) or Subject Alternative Name (SAN) that matches `www.team<T>.ncaecybergames.org` exactly. If it’s a self-signed cert for "localhost" or "Team-Router," the check will fail.  
* **Trust Chain:** The certificate must be signed by the competition's **Certificate Authority (172.18.0.38)**. The scoring engine is pre-configured to trust that CA; if you use a random self-signed cert, it will be marked as "Invalid."

### **3\. The Content Requirement ("Web content is correct")**

Even if the SSL is perfect, the scoring engine still looks at the actual HTML code of the page.

* **The String:** It is looking for the specific string **"team\#"** (where \# is your team number) on the root webpage.  
* **Checked through the router:** This means your NAT rules for **Port 443** must be active and correctly pointing to your internal Web Server.

GENERATING THE CSR:

```bash
openssl req -new -newkey rsa:2048 -nodes -keyout team<T>.key -out team<T>.csr \
-subj "/C=US/ST=State/L=City/O=NCAE/OU=CyberGames/CN=www.team<T>.ncaecybergames.org"
```

- **`team<T>.key`**: This is your private key. **Never** share this or upload it to the CA.  
- **`team<T>.csr`**: This is the file you will provide to the CA server.  
- **`CN`**: The "Common Name" must match the scoring domain exactly: [`www.team`](http://www.team)`<T>.ncaecybergames.org`.

### **2\. Submit the CSR to the CA**

Since you are in a competition environment, you likely need to transfer the `.csr` file to the CA server or paste its contents into a web portal provided at **172.18.0.38**.

* To view the content to copy/paste: `cat team<T>.csr`  
* The CA will process this and return a signed certificate (usually ending in `.crt` or `.pem`).

---

### **3\. Install the Certificate on your Web Server**

Once you have the signed certificate from the CA, you need to configure your web server (e.g., Nginx or Apache) to use it.

Example for Nginx:

```bash
server {
    listen 443 ssl;
    server_name www.team<T>.ncaecybergames.org;

    ssl_certificate /etc/ssl/certs/team<T>.crt; # The file you got from CA
    ssl_certificate_key /etc/ssl/private/team<T>.key; # The file you generated in Step 1

    location / {
        root /var/www/html;
        index index.html;
    }
}
```

### **4\. Final Scoring Verification**

Once the service is restarted, the scoring engine will check the following:

* **Handshake**: It connects via your router (NAT port 443).  
* **Certificate**: It verifies the signature against the **CA (172.18.0.38)**.  
* **Domain**: It ensures the certificate name matches the DNS entry.  
* **Content**: It looks for the **"team\#"** string in your `index.html`.

Let’s hope this is correct:

To ensure you capture all 1,000 DNS points (500 for Internal and 500 for External), you must treat your **DNS VM (192.168.t.12)** as the source of truth for two distinct zones. The Competition Infrastructure server (172.18.0.12) is merely a "referral service" that points external traffic to your router.

Here are the full end-to-end instructions for the DNS VM and the Router.

---

## **Step 1: Configure the DNS VM (192.168.t.12)**

You need to create two zone files. In most Linux environments, these are managed in /etc/bind/named.conf.local or a similar directory.

### **1.1 Create the Internal Zone (teamX.net)**

This satisfies the "Internal DNS" requirement for hosts checked from inside your LAN.

* **File Path:** /etc/bind/db.teamX.net  
* **Contents:**

Plaintext

```
$TTL 60
@   IN  SOA  ns1.teamX.net. admin.teamX.net. (2026020601 3H 1H 1W 1H)
    IN  NS   ns1.teamX.net.
ns1 IN  A    192.168.t.12
www IN  A    192.168.t.5
db  IN  A    192.168.t.7
```

### **1.2 Create the External Zone (teamX.ncaecybergames.org)**

This satisfies the "External DNS" requirement scored through the router.

* **File Path:** /etc/bind/db.teamX.external  
* **Contents:**

Plaintext

```
$TTL 60
@   IN  SOA  ns1.teamX.ncaecybergames.org. admin.teamX.ncaecybergames.org. (2026020601 3H 1H 1W 1H)
    IN  NS   ns1.teamX.ncaecybergames.org.
ns1 IN  A    172.18.13.t  ; Points to your Router's WAN IP
www IN  A    172.18.13.t  ; Points to your Router's WAN IP
```

\[\!IMPORTANT\]

In the **External Zone**, the A records point to your **Router's WAN IP (172.18.13.t)**, not the internal 192.168.t.x IPs. This is because external users only "see" your router's external face.

---

## **Step 2: Configure the MikroTik Router (DONE)**

The "External DNS" points are only awarded if queries from the **Infrastructure DNS (172.18.0.12)** can reach your VM.

### **2.1 Add Destination NAT Rules**

Run these commands to pass Port 53 (DNS) traffic through the firewall.

Bash

```
/ip firewall nat add chain=dstnat dst-address=172.18.13.t protocol=udp dst-port=53 \
    action=dst-nat to-addresses=192.168.t.12 to-ports=53 comment="External DNS NAT (UDP)"

/ip firewall nat add chain=dstnat dst-address=172.18.13.t protocol=tcp dst-port=53 \
    action=dst-nat to-addresses=192.168.t.12 to-ports=53 comment="External DNS NAT (TCP)"
```

### **2.2 Permit Forwarding in the Filter**

Ensure your firewall filter doesn't block this new NAT'd traffic.

Bash

```
/ip firewall filter add chain=forward connection-nat-state=dstnat action=accept \
    comment="Allow NAT'd DNS traffic to reach VM"
```

---

## **Step 3: End-to-End Verification**

To ensure you aren't missing points, run these tests from an **External Kali VM (172.18.15.t)**.

### **3.1 Test External Resolution**

Query your router's WAN IP directly to see if the NAT and VM are talking.

Bash

```
dig @172.18.13.t www.teamX.ncaecybergames.org
```

*   
  **Success:** You get an ANSWER SECTION with your WAN IP. This confirms the **500 pts** for External DNS.

### **3.2 Test Internal Resolution**

From your **Internal Kali (192.168.t.10)**, query your VM's internal IP.

Bash

```
nslookup teamX.net 192.168.t.12
```

*   
  **Success:** It resolves correctly. This confirms the **500 pts** for Internal DNS.

---

### **Summary Checklist**

| Component | Setting | Goal |
| :---- | :---- | :---- |
| **DNS VM** | Zone teamX.net | Internal 500 points |
| **DNS VM** | Zone teamX.ncaecybergames.org | External 500 points |
| **Router** | NAT Port 53 (UDP/TCP) | Allows external scoring engine to reach VM |
| **Scoring** | String "team\#" in web content | Web Content points (1500) |

**\*\*\*HARDENING THE DNS SERVER\*\*\***

To ensure your **BIND9** DNS server is both functional for scoring and hardened against Red Team abuse, you need to configure the main options file. This prevents your server from being used in **DNS Amplification attacks** (being an "open relay") while still allowing it to answer authoritative queries from the outside.

---

## **1\. Hardening the BIND Options**

Edit your /etc/bind/named.conf.options file. This configuration tells the server who is allowed to ask recursive questions (like "What is https://www.google.com/url?sa=E\&source=gmail\&q=google.com?") versus who can only ask about your specific team zones.

Plaintext

```
acl "trusted" {
        127.0.0.0/8;
        192.168.t.0/24;  # Your LAN Subnet
};

options {
        directory "/var/cache/bind";

        # Only allow your own internal machines to use this for general internet browsing
        recursion yes;
        allow-recursion { "trusted"; };

        # Allow anyone (including the Scorer) to ask about your specific team zones
        allow-query { any; };

        # Prevent unauthorized zone transfers (Red Team reconnaissance)
        allow-transfer { none; };

        dnssec-validation auto;
        listen-on-v6 { any; };
};
```

---

## **2\. Setting Up the Zone Definitions**

Now, tell BIND where to find the zone files we discussed. Edit /etc/bind/named.conf.local:

Plaintext

```
# The Internal Zone for teamX.net scoring
zone "teamX.net" {
    type master;
    file "/etc/bind/db.teamX.net";
};

# The External Zone for teamX.ncaecybergames.org scoring
zone "teamX.ncaecybergames.org" {
    type master;
    file "/etc/bind/db.teamX.external";
};
```

---

## **3\. Final Verification Commands**

Once you restart the service (systemctl restart bind9), run these two checks to ensure you've secured the "External DNS resolve correctly" requirement:

### **A. The "Through the Router" Check**

From an **External Kali VM (172.18.15.t)**, try to resolve your web server.

Bash

```
dig @172.18.13.t www.teamX.ncaecybergames.org
```

*   
  **Target Result:** You receive your **Router WAN IP (172.18.13.t)** as the answer.  
* **What this proves:** Your **MikroTik NAT** is working, and your DNS VM is answering external queries.

### **B. The "Open Relay" Hardening Check**

From the same **External Kali**, try to ask your router for a domain you don't own.

Bash

```
dig @172.18.13.t google.com
```

*   
  **Target Result:** status: REFUSED or no answer.  
* **What this proves:** Red Team cannot use your DNS server to attack others.

---

### **End-to-End DNS Summary**

| Component | Goal | Status Check |
| :---- | :---- | :---- |
| **Zone teamX.net** | Resolve internal hostnames for 500 pts. | nslookup teamX.net 192.168.t.12 works. |
| **Zone teamX.ncaecybergames.org** | Resolve external hostnames for 500 pts. | dig @172.18.13.t www.teamX.ncaecybergames.org works. |
| **Recursion Limits** | Prevent DNS Amplification attacks. | External queries for unknown domains are **REFUSED**. |

# Database Stuff

### **Check for the Database and Tables**

First, list all databases to find the one the app created. It is likely named `etechacademy`, `academy`, or `flaskapp`.

Bash

```
sudo -u postgres psql -l
```

Once you see the database name, check for the tables (specifically the user table):

Bash

```
# Replace 'etechacademy' with the actual DB name if different
sudo -u postgres psql -d etechacademy -c "\dt"
```

### **2\. Verify the Scoring User**

If you see a `users` table, check if the `admin` user exists so the scoring engine can log in:

Bash

```
sudo -u postgres psql -d etechacademy -c "SELECT username FROM users WHERE username='admin';"
```

---

### **3\. If the Tables are Missing (Force Generation)**

If the database is empty, the "generate on start up" logic failed. This usually happens because:

1. **Permissions:** The Flask app doesn't have permission to create tables.  
2. **Service order:** The app tried to start before PostgreSQL was ready.

**The Fix:** Restart the application service. Since it's a Flask app, it likely uses SQLAlchemy to `create_all()` when the service starts.

Bash

```
sudo systemctl restart postgresql
sudo systemctl restart etechacademy
```

---

### **4\. Emergency: Manual User Creation**

If the tables exist but the `admin` user is missing (a common Red Team "delete" move), you can manually insert the scoring user so you don't lose points:

Bash

```
# Warning: This assumes a simple table structure. 
# If the app uses password hashing (likely), manual insertion might not work 
# unless you know the hash format. Try restarting the app first!
sudo -u postgres psql -d etechacademy -c "INSERT INTO users (username, password) VALUES ('admin', 'admin123');"
```

---

### **5\. Final "Green Score" Configuration Summary**

To ensure you hit all rubric requirements, run this final sweep:

| Requirement | Command to Verify |
| :---- | :---- |
| **Valid SSL** | \`openssl s\_client \-connect localhost:443 \-servername team.ncaecybergames.org |
| **Certbot Tag** | `grep "no-random-sleep-on-renew" /lib/systemd/system/certbot.service` |
| **App Status** | `systemctl is-active etechacademy` |
| **DB Connectivity** | \`sudo tail \-n 20 /var/log/syslog |

### **6\. Lock It Down**

The Red Team will try to delete your `admin` user or stop your service again. Use the "immutable" trick on your config and service files now that they work:

Bash

```
sudo chattr +i /etc/systemd/system/etechacademy.service
sudo chattr +i /var/lib/etechacademy/config.py # Replace with actual config file
```

[image1]: <data:image/png;base64,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>