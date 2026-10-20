#!/usr/bin/env bash





#
# Environment Setup
#
# Define location of logs
# Find log files currently being logged to
declare -r log_dir='/var/log/sessions'
is_open="$(lsof -c script -a +D "${log_dir}" -Fn 2>/dev/null | grep '^n' | cut -c2-)"
declare -r is_open





#
# Main Logic
#
# Iterate a check over every file in the logging directory
for file in "${log_dir}"/*; do
	# Skip if it's not a regular file & remove symlinks
	[[ -f "${file}" ]] || continue
	[[ -h "${file}" ]] && rm -fv "${file}"
	#
	# Apply defaults
	chown 0:0 "${file}" && chmod 600 "${file}"
	#
	# Check if this specific file is in our list (or is being prepared for logging)
	if
		grep -qx "${file}" <<<"${is_open}" ||
		[[ "$(stat -c %s "${file}")" == 0 ]];
	then
		# File is actively being logged to
		# Add append-only (+a)
		chattr +a "${file}" && echo "Made append-only: ${file@Q}"
	else
		# File is idle/finished
		# Remove append-only (-a) & set immutable (+i)
		chattr -a +i "${file}" && echo "Made immutable: ${file@Q}"
	fi
done
