#!/usr/bin/env bash





#
# Environment Setup
#
log_dir='/var/log/sessions'
declare -A open_logs
while read -rd '' path; do
	[[ -f ${path} ]] || continue
	open_logs["${path}"]=1
done < <(
	lsof -c script -F n0 -- +D "${log_dir}" |
		grep -a '^n' |
		cut -c2- |
		sort -u
)





#
# Main Logic
#
# Iterate a check over every log in the logging directory
for path in "${log_dir}"/*; do
	# Skip if it's not a regular path & remove symlinks
	[[ -f "${path}" ]] || continue
	#
	# Apply defaults
	chown 0:0 -- "${path}"
	chmod 600 -- "${path}"
	#
	# Check if this specific path is in our list (or is being prepared for logging)
	if
		(("${open_logs["${path}"]}")) ||
		[[ "$(stat -c %s "${path}")" == 0 ]];
	then
		# Logging is still occuring
		# Set append-only (+a)
		chattr -V +a -- "${path}"
	else
		# Logging is finished
		# RSet immutable (+i)
		chattr -V +i -- "${path}"
	fi
done
