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
