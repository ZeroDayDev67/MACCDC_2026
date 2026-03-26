#!/bin/bash
sudo systemctl stop sshd.socket
sudo systemctl disable sshd.socket
sudo systemctl stop ssh.service  
sudo systemctl disable ssh.service
sudo systemctl mask ssh
sudo systemctl mask sshd.socket
sudo systemctl stop rpcbind
sudo systemctl stop rpcbind.socket
sudo systemctl disable rpcbind
sudo systemctl disable rpcbind.socket
sudo systemctl mask rpcbind
sudo systemctl mask rpcbind.socket
sudo systemctl stop cokpit.socket
sudo systemctl disable cokpit.socket
sudo systemctl mask cokpit.socket
