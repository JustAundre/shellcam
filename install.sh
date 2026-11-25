#!/usr/bin/env bash
#
# Environment Setup
#
cd "${0##*/}" || exit 1





#
# Register Shellcam
#
# Create the logging directory
default_path="/var/log/shellcam"
while true; do
	read -r -p "(Submit nothing to default to \"${default_path}\")"$'\nEnter path to directory for storing Shellcam logs: ' path
	resolved_path="$(realpath "${path:-"${default_path}"}")"
	if [[ ${resolved_path} != "${path}" ]]; then
		log i "${path@Q} resolved to ${resolved_path@Q}."
	fi
	if [[ -f ${resolved_path} ]] && ! rm -v -i "${resolved_path}"; then
		log w 'Refused to delete file.'
		continue
	fi
	if [[ -n "$(find "${resolved_path}" -maxdepth 1 -mindepth 1)" ]]; then
		log 'Refused to log to non-empty pre-existing directory.'
	fi
	break
done
mkdir -v -p "${resolved_path}"
chown -c 0:0 "${resolved_path}"
chmod -c 640 "${resolved_path}"
if hash systemctl &>/dev/null; then
	log i 'Restarting SSH server via SystemCTL command...'
	systemctl restart sshd || systemctl restart ssh ||
		log e 'Failed.'
elif hash service &>/dev/null; then
	log i 'Restarting SSH server via "service" command...'
	service sshd restart || service ssh restart ||
		log e 'Failed.'
else
	log i 'Restarting SSH server by force...'
	mapfile -t sshd_pids < <(pgrep sshd)
	kill "${sshd_pids[@]}"
	sleep 1
	for pid in "${sshd_pids[@]}"; do
		[[ -d /proc/${pid} ]] || kill -9 "${pid}"
	done
fi





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
