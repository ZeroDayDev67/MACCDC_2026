#!/bin/bash
who | awk '!/root/{ cmd="/usr/bin/pkill -KILL -u " $1; system(cmd)}'