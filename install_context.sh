#!/bin/bash -e

wget -P /tmp https://github.com/OpenNebula/addon-context-linux/releases/download/v6.2.0/one-context_6.2.0-1.deb
apt install --yes /tmp/one-context_6.2.0-1.deb
rm /tmp/one-context_6.2.0-1.deb