#!/usr/bin/env bash
#
# Author: Marcin Szydelski
#
# Send an e-mail when forked repo is behind.
#
# Changelog:
# 2023.12.27 - init

REPO_LIST=("firmware-manager" "system76-acpi-dkms" "system76-dkms" "system76-driver" "system76-firmware" "system76-io-dkms" "system76-power")

# Function to check for updates and fetch if needed
check_for_updates() {
  if curl -s "https://github.com/szydell/${1}" | grep -qE "commit.*behind"; then
    echo "behind"
  else
    echo "up to date"
  fi
}

behinds=()

notify=false
echo "RAPORT"
for r in "${REPO_LIST[@]}"; do
  state=$(check_for_updates "$r")
  echo "$r: $state"
  if [[ $state == "behind" ]]; then
    notify=true
    behinds+=("$r")
  fi
done

if [[ $notify ]]; then
  m=$(head -1 ~/.config/mail.notify)
  p=$(tail -1 ~/.config/mail.notify)
  curl -s --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
    --mail-from "${m}" \
    --mail-rcpt "${m}" \
    --user "${m}:${p}" \
    -T <(echo -e "From: ${m}\nTo: ${m}\nSubject: Notification: system76 update available\n\nUpgrade available:\n${behinds[*]}")
fi
