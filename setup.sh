#!/usr/bin/env bash

# adopted from https://github.com/Luctia/ezarr/blob/main/setup.sh

CONFIG_DIR=/config
DATA_DIR=/data

# Make directories
sudo mkdir -pv ${CONFIG_DIR}/{sonarr,radarr,qbittorrent,plex,sabnzbd}
sudo mkdir -pv ${DATA_DIR}/{torrents,usenet,media}/{tv,movies}

# Set permissions
sudo chmod -Rv 775 ${DATA_DIR}/
sudo chown -Rv ${USER}:${USER} ${CONFIG_DIR}/
sudo chown -Rv ${USER}:${USER} ${DATA_DIR}/
