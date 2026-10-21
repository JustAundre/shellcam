#!/usr/bin/env bash





#
# Environment Setup
#
count=0
HOME="$(getent passwd "$(id -nu)" | cut -d: -f6)"
while [[ -f ${log_file} || -z ${log_file} ]]; do
	((count++))
	log_file="/var/log/sessions/${LOGNAME}-${count}.log"
done





#
# Main Logic
#
# Stop & log non-interactive sessions
if [[ ! -t 0 ]]; then
	# ...plus any commands
	[[ -n ${SSH_ORIGINAL_COMMAND} ]] && cmd="with command ${SSH_ORIGINAL_COMMAND}"
	systemd-cat -p3 -t sshd <<< "${LOGNAME}/${UID} from ${SSH_CLIENT} attempted to run non-interactive command: (${cmd})"
	exit 255
fi
#
# Start logging
[[ -x /opt/bullsh/bull.sh ]] &&
	exec -c env -i\
		TERM="${TERM}"\
		SSH_CLIENT="${SSH_CLIENT}"\
		SSH_CONNECTION="${SSH_CONNECTION}"\
		SSH_TTY="${SSH_TTY}"\
		SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}"\
		-- /usr/bin/script "${log_file}" -afqc "su -p $(id -nu) -s /bin/bash -lc /opt/bullsh/bull.sh"
exec -c env -i\
	TERM="${TERM}"\
	SSH_CLIENT="${SSH_CLIENT}"\
	SSH_CONNECTION="${SSH_CONNECTION}"\
	SSH_TTY="${SSH_TTY}"\
	SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}"\
	-- /usr/bin/script "${log_file}" -afqc "su -p $(id -nu) -s /bin/bash -l"
