#!/bin/bash

systemctl disable cups-browsed
systemctl stop cups-browsed
systemctl mask cups-browsed