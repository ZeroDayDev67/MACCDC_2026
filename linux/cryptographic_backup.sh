#!/bin/bash

#cryptographic_backup

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