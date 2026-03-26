#!/bin/bash

#directories to backup

sudo tar -czpvf /media/backup/backup.tar.gz --exclude=/var/cache/man/.sys_cache /home /etc /root /usr/ /opt /srv /var