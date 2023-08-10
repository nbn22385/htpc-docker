#!/usr/bin/env bash

# adopted from https://github.com/Luctia/ezarr/blob/main/setup.sh

CONFIG_DIR=/config
DATA_DIR=/data

# Make directories
sudo mkdir -pv ${CONFIG_DIR}/{bazarr,overseerr,plex,prowlarr,qbittorrent,radarr,sabnzbd,sonarr,wireguard}

# Set permissions
sudo chmod -Rv 775 ${DATA_DIR}/
sudo chown -Rv ${USER}:${USER} ${CONFIG_DIR}/
sudo chown -Rv ${USER}:${USER} ${DATA_DIR}/
