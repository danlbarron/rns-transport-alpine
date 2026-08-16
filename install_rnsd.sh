#!/bin/sh

# Variables
COMMUNITY_REPO=https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
PIPX_PACKAGE=rns
DAEMON=rnsd
DAEMON_COMMAND=/usr/local/bin/rnsd
DAEMON_COMMAND_ARGS=--service
DAEMON_USER=rnsuser
CRONJOB_PATH=/etc/periodic/daily/upgrade_rnsd

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

  if ! id $DAEMON_USER >/dev/null 2>&1; then
    log_error "${DAEMON_USER} not created."
    echo 'Please run the following command and relaunch this installer.'
    echo "adduser ${DAEMON_USER}"
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

  if [ ! -e $DAEMON_COMMAND ]; then
    pipx install --global $PIPX_PACKAGE
    log_info "Installed PIPX Dependency: ${PIPX_PACKAGE}"
  fi
}

install_daemon() {
  if [ -e /etc/init.d/$DAEMON ]; then
    return 0
  fi

  cat <<EOT >> /etc/init.d/$DAEMON
#!/sbin/openrc-run
supervisor=supervise-daemon
command="$DAEMON_COMMAND"
command_args="$DAEMON_COMMAND_ARGS"
command_user="$DAEMON_USER"
pidfile="/run/$(echo '${RC_SVCNAME}').pid"
EOT

  chmod +x /etc/init.d/$DAEMON
  rc-update add $DAEMON
  rc-service $DAEMON start
  log_info "Installed Daemon: ${DAEMON}"
}

install_cronjob() {
  if [ -e $CRONJOB_PATH ]; then
    return 0
  fi

  cat <<EOT >> $CRONJOB_PATH
#!/bin/sh
rc-service $DAEMON stop && pipx upgrade --global $PIPX_PACKAGE && rc-service $DAEMON start
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
