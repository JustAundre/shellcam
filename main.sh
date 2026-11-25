#!/usr/bin/env bash





#
# Environment Setup
#
USER="$(id -n -u)"
HOME="$(getent passwd "${USER}" | cut -d ':' -f 6)"
count=0
log_file="/var/log/shellcam/${USER}-${count}.log"
while [[ -f ${log_file} ]]; do
	((count++))
	log_file="/var/log/shellcam/${USER}-${count}.log"
done





#
# Main Logic
#
# Stop & log non-interactive sessions
if [[ ! -t 0 ]]; then
	# ...plus any commands
	systemd-cat -p 3 -t shellcam <<< "${USER}/${UID}@${SSH_CLIENT@Q} attempted non-interactive command: ${SSH_ORIGINAL_COMMAND@Q}"
	exit 255
fi
#
# Start logging
cmd=(
	exec -c -- env -i --
	"TERM=${TERM}"
	"SSH_CLIENT=${SSH_CLIENT}"
	"SSH_CONNECTION=${SSH_CONNECTION}"
	"SSH_TTY=${SSH_TTY}"
	"SSH_ORIGINAL_COMMAND=${SSH_ORIGINAL_COMMAND}"
	"su -p ${SUDO_USER} -s /bin/bash -l"
	/usr/bin/script -a -f -q -c
	-- "${log_file}"
)
if [[ -x ${custom_exec} ]]; then
	cmd[-2]+=" -c ${custom_exec}"
fi
"${cmd[@]}"
