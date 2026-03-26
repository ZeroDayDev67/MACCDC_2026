#/bin/bash

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

sudo ufw reload


#make sure to disable ipv6 completely by going into ufw config using vi /etc/default/ufw