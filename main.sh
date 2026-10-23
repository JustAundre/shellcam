#!/usr/bin/env bash





#
# Environment Setup
#
bullsh_exec='/opt/bullsh/main.sh'
USER="$(id -nu)"
HOME="$(getent passwd "${USER}" | cut -d: -f6)"
count=0
log_file="/var/log/sessions/${USER}-${count}.log"
while [[ -f ${log_file} ]]; do
	((count++))
	log_file="/var/log/sessions/${USER}-${count}.log"
done





#
# Main Logic
#
# Stop & log non-interactive sessions
if [[ ! -t 0 ]]; then
	# ...plus any commands
	systemd-cat -p3 -t sshd <<< "${USER}/${UID}@${SSH_CLIENT@Q} attempted non-interactive command: ${SSH_ORIGINAL_COMMAND@Q}"
	exit 255
fi
#
# Start logging
cmd=(
	exec -c -- env -i --
	TERM="${TERM}"
	SSH_CLIENT="${SSH_CLIENT}"
	SSH_CONNECTION="${SSH_CONNECTION}"
	SSH_TTY="${SSH_TTY}"
	SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}"
)
if [[ -x ${bullsh_exec} ]]; then
	cmd+=(/usr/bin/script -afqc "su -p ${SUDO_USER} -s /bin/bash -lc ${bullsh_exec}" -- "${log_file}")
else
	cmd+=(/usr/bin/script -afqc "su -p ${SUDO_USER} -s /bin/bash -l" -- "${log_file}")
fi
"${cmd[@]}"
