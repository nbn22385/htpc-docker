#!/usr/bin/env bash

# adopted from https://github.com/Luctia/ezarr/blob/main/setup.sh

CONFIG_DIR=/config
DATA_DIR=/mnt/usb

# Make directories
sudo mkdir -pv ${CONFIG_DIR}/{bazarr,duckdns,grafana,jellyfin,nginx,overseerr,plex,prowlarr,qbittorrent,radarr,sabnzbd,sonarr,tautulli,wireguard}
sudo mkdir -pv ${DATA_DIR}/{torrents,usenet,media}/{tv,movies}
sudo mkdir -pv /pd_zurg/{cache,config,log,mnt,RD}

# Set permissions
sudo chmod -Rv 775 ${DATA_DIR}/
sudo chown -Rv ${USER}:${USER} ${CONFIG_DIR}/
sudo chown -Rv ${USER}:${USER} ${DATA_DIR}/
sudo chown -Rv ${USER}:${USER} /pd_zurg
