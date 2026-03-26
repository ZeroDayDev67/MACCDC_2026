#!/bin/bash

sudo mkdir /var/backups/
sudo dd if=/dev/urandom of=/var/backups/inital_backup.tar.gz bs=1M count=10