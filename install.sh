#!/bin/sh

# Variables
COMMUNITY_REPO=https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
RNS_DAEMON_USER=rnsuser
RNS_DAEMON_PATH=/etc/init.d/rnsd
CRONJOB_PATH=/etc/periodic/daily/do-updates

# Logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}→${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}!${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

# Installation Functions

script_prechecks() {
  if [ $(id -u) -ne 0 ]; then
    log_error 'This script must be run as root.'
    exit 1
  fi

  if ! id $RNS_DAEMON_USER >/dev/null 2>&1; then
    log_error "${RNS_DAEMON_USER} not created."
    echo 'Please run the following command and relaunch this installer.'
    echo "adduser ${RNS_DAEMON_USER}"
    exit 1
  fi
}

install_dependencies() {
  if ! grep -Fxq $COMMUNITY_REPO /etc/apk/repositories; then
    echo $COMMUNITY_REPO >> /etc/apk/repositories
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    apk add pipx
    log_info 'Installed APK Dependency: pipx'
  fi

  if [ ! -e /usr/local/bin/rnsd ]; then
    pipx install --global rns
    log_info 'Installed PIPX Dependency: rns'
  fi
}

install_daemon() {
  if [ -e $RNS_DAEMON_PATH ]; then
    return 0
  fi

  cat <<EOT >> $RNS_DAEMON_PATH
#!/sbin/openrc-run
command="/usr/local/bin/rnsd"
command_args="--service"
command_background=true
command_user="$RNS_DAEMON_USER"
pidfile="/run/$(echo '${RC_SVCNAME}').pid"
EOT

  chmod +x $RNS_DAEMON_PATH
  rc-update add rnsd
  rc-service rnsd start
  log_info "Installed Daemon: ${RNS_DAEMON_PATH}"
}

install_cronjob() {
  if [ -e $CRONJOB_PATH ]; then
    return 0
  fi

  cat <<EOT >> $CRONJOB_PATH
#!/bin/sh
apk update && apk upgrade
rc-service rnsd stop && pipx upgrade-all --global && rc-service rnsd start
EOT

  chmod +x $CRONJOB_PATH
  log_info "Installed Cron Job: ${CRONJOB_PATH}"
}

# Entry Point

script_prechecks
install_dependencies
install_daemon
install_cronjob
log_info 'Installation Complete'