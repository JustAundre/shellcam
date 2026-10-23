#!/usr/bin/env bash
#
# Environment Setup
#
cd "${0##*/}" || exit 1





#
# Register Shellcam
#
# Create the logging directory
mkdir -v -p /var/log/sessions
chown -c 0:0 /var/log/sessions
chmod -c 640 /var/log/sessions
#
# Patch SSHD configuration and sudoers file, then restart SSHD.
visudo -cf cnf/sudoers || exit 1
install -m 440 -o 0 -g 0 -D -v cnf/sudoers /etc/sudoers.d/shellcam
cat cnf/sshd_config >>/etc/ssh/sshd_config
systemctl restart sshd || systemctl restart ssh





#
# Enroll Log Protection Service
#
# Install monitor service
install -v -m 600 -o 0 -g 0 ./sc-log-locker/service.service /etc/systemd/system/shellcam-monitor.service
install -v -m 600 -o 0 -g 0 ./sc-log-locker/service.path /etc/systemd/system/shellcam-monitor.path
#
# Register and enable monitor service
systemctl daemon-reload
systemctl enable --now sc-monitor.service
systemctl enable --now sc-monitor.path
