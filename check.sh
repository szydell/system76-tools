#!/usr/bin/env bash
#
# Author: Marcin Szydelski
#
# Send an e-mail when forked repo is behind.
#
# Changelog:
# 2024.02.14 - don't check on github, but fetch locally and check git log
# 2023.12.27 - init

REPO_LIST=("firmware-manager" "system76-acpi-dkms" "system76-dkms" "system76-driver" "system76-firmware" "system76-io-dkms" "system76-power")
DEV_DIR="/home/szydell/dev/76-system/"

# Function to check for updates
check_for_updates() {
  cd $DEV_DIR/"${1}" || echo "error"
  git fetch upstream > /dev/null 2>&1
  git checkout master > /dev/null 2>&1
  commits_behind=$(git log master..upstream/master 2>&1 | grep -c "commit")
  echo "$commits_behind"
}

behinds=()

notify="no"
echo "RAPORT"
for r in "${REPO_LIST[@]}"; do
  commits_behind=$(check_for_updates "$r")
  echo "$r -> commits behind: $commits_behind"
  if [[ "$commits_behind" -gt "0" ]]; then
    notify="yes"
    behinds+=("$r->$commits_behind")
  fi
done

if [[ $notify == "yes" ]]; then
  m=$(head -1 ~/.config/mail.notify)
  p=$(tail -1 ~/.config/mail.notify)
  curl -s --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
    --mail-from "${m}" \
    --mail-rcpt "${m}" \
    --user "${m}:${p}" \
    -T <(echo -e "From: ${m}\nTo: ${m}\nSubject: Notification: system76 update available\n\nUpgrade available:\n${behinds[*]}")
fi
