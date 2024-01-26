#!/bin/bash

architecture=$(uname -m)

if [[ ! "${PUID}" -eq 0 ]] && [[ ! "${PGID}" -eq 0 ]]; then
    printf "\e[0;32m*****EXECUTING USERMOD*****\e[0m\n"
    usermod -o -u "${PUID}" steam
    groupmod -o -g "${PGID}" steam
    printf "\e[0;32m*****EXECUTING USERMOD COMPLETE*****\e[0m\n"
else
    printf "\033[31mRunning as root is not supported, please fix your PUID and PGID!\n"
    exit 1
fi

mkdir -p /palworld/backups
chown -R steam:steam /palworld

if [ "${UPDATE_ON_BOOT}" = true ]; then
    printf "\e[0;32m*****STARTING INSTALL/UPDATE*****\e[0m\n"
    command1='/home/steam/steamcmd/steamcmd.sh +force_install_dir /palworld +login anonymous +app_update 2394010 validate +quit'
    if [ "$architecture" == "arm" ] || [ "$architecture" == "aarch64" ]; then
        echo "arm architecture detected, using FEXBash to run steamcmd"
        su steam -c "FEXBash -c \"$command1\""
    else
        su steam -c "$command1"
    fi
    printf "\e[0;32m*****INSTALL/UPDATE COMPLETE*****\e[0m\n"
fi

term_handler() {
    if [ "${RCON_ENABLED}" = true ]; then
        rcon-cli save
        rcon-cli shutdown 1
    else # Does not save
        kill -SIGTERM "$(pidof PalServer-Linux-Test)"
    fi
    tail --pid=$killpid -f 2>/dev/null
}

trap 'term_handler' SIGTERM

./start.sh &
killpid="$!"
wait $killpid
