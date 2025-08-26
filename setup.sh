#!/usr/bin/env bash
set -euo pipefail

# Set owners
chown -R demichevaa:demichevaa /opt/daa

# Also add secondary user to own/write
chown -R demichevaa_personal:demichevaa_personal /opt/daa

# Make both users members of a common group
groupadd -f daausers
usermod -aG daausers demichevaa
usermod -aG daausers demichevaa_personal
chown -R :daausers /opt/daa

# Full access for both users
chmod -R 770 /opt/daa

# Ensure new files inherit group perms
chmod g+s /opt/daa

