#!/bin/bash
getent passwd | awk -F: -v me="$(whoami)" '$3>=1000 && $1!="root" && $1!=me {print $1}' | tee locked_users.txt | xargs -I {} sh -c 'echo "Locking: {}" && sudo passwd -l "{}"'