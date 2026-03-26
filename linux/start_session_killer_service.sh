#!/bin/bash

systemctl daemon-reload
systemctl enable session-killer.service
systemctl start session-killer.service
systemctl status session-killer.service  # Verify it's active