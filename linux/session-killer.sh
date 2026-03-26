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