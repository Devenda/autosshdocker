#!/bin/sh

# based on https://github.com/jnovack/docker-autossh
#This is required to get it to work in windows, chmod cannot be done on ntfs (which happens when mounting)

# to be able to use host.docker.internal on linux:
function fix_linux_internal_host() {
  DOCKER_INTERNAL_HOST="host.docker.internal"

  if ! grep $DOCKER_INTERNAL_HOST /etc/hosts > /dev/null ; then
    DOCKER_INTERNAL_IP=`/sbin/ip route | awk '/default/ { print $3 }' | awk '!seen[$0]++'`
    echo -e "$DOCKER_INTERNAL_IP\t$DOCKER_INTERNAL_HOST" | tee -a /etc/hosts > /dev/null
    echo "Added $DOCKER_INTERNAL_HOST to hosts /etc/hosts"
  fi
}

fix_linux_internal_host


# procede with startup config
mkdir -p /ssh
cp /key/id_rsa ${SSH_KEY_FILE:=/id_rsa}

chmod 0400 ${SSH_KEY_FILE:=/id_rsa}

STRICT_HOSTS_KEY_CHECKING=no
KNOWN_HOSTS=${SSH_KNOWN_HOSTS:=/known_hosts}
if [ -f "${KNOWN_HOSTS}" ]; then
    chmod 0400 ${KNOWN_HOSTS}
    KNOWN_HOSTS_ARG="-o UserKnownHostsFile=${KNOWN_HOSTS}"
    STRICT_HOSTS_KEY_CHECKING=yes
fi

# Pick a random port above 32768
DEFAULT_PORT=$RANDOM
let "DEFAULT_PORT += 32768"
echo [INFO] Tunneling ${SSH_HOSTUSER:=root}@${SSH_HOSTNAME:=localhost}:${SSH_TUNNEL_REMOTE:=${DEFAULT_PORT}} to ${SSH_TUNNEL_HOST=localhost}:${SSH_TUNNEL_LOCAL:=22}

echo autossh \
 -M 0 \
 -N \
 -o StrictHostKeyChecking=${STRICT_HOSTS_KEY_CHECKING} ${KNOWN_HOSTS_ARG:=} \
 -o ServerAliveInterval=5 \
 -o ServerAliveCountMax=1 \
 -o "ExitOnForwardFailure yes" \
 -t -t \
 -i ${SSH_KEY_FILE:=/id_rsa} \
 ${SSH_MODE:=-R} ${SSH_TUNNEL_REMOTE}:${SSH_TUNNEL_HOST}:${SSH_TUNNEL_LOCAL} \
 -p ${SSH_HOSTPORT:=22} \
 ${SSH_HOSTUSER}@${SSH_HOSTNAME}

AUTOSSH_PIDFILE=/autossh.pid \
AUTOSSH_POLL=10 \
AUTOSSH_LOGLEVEL=0 \
AUTOSSH_LOGFILE=/dev/stdout \

autossh \
 -M 0 \
 -N \
 -o StrictHostKeyChecking=${STRICT_HOSTS_KEY_CHECKING} ${KNOWN_HOSTS_ARG:=}  \
 -o ServerAliveInterval=5 \
 -o ServerAliveCountMax=1 \
 -o "ExitOnForwardFailure yes" \
 -t -t \
 -i ${SSH_KEY_FILE:=/id_rsa} \
 ${SSH_MODE:=-R} ${SSH_TUNNEL_REMOTE}:${SSH_TUNNEL_HOST}:${SSH_TUNNEL_LOCAL} \
 -p ${SSH_HOSTPORT:=22} \
 ${SSH_HOSTUSER}@${SSH_HOSTNAME}
