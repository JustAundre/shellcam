#!/usr/bin/env bash





#
# Main Logic
#
# Iterate a check over every file in the logging directory
declare -A open_files
while read -rd '' path; do
	open_files["${path}"]=1
done < <(lsof -c script -a +D /var/log/sessions -F n0 lsof | grep -Z '^n' | cut -z -c2-)
for path in "${log_dir}"/*; do
	# Skip if it's not a regular file & remove symlinks
	[[ -f ${path} ]] || continue
	[[ -h ${file} ]] && unlink -v "${path}"
	#
	# Apply defaults
	chown -c 0:0 "${path}"
	chmod -c 600 "${path}"
	#
	# Check if this specific file is in our list (or is being prepared for logging)
	if
		((open_files["${path}"])) ||
		[[ "$(stat -c %s "${path}")" == 0 ]];
	then
		# Script command has file open
		chattr -V +a "${path}"
	else
		# File is idle/finished
		chattr -V +i "${path}"
	fi
done
