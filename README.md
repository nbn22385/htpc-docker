# Home media server

Plex / qBittorrent / SABnzbd / VPN

Media download, sort, and serve with the desired quality and subtitles, behind
a VPN (optional), ready to watch, in a beautiful media player. All automated.

## Overview

This setup provides the ability to download media using BitTorrent (via
qBittorrent, with optional VPN support) and/or Usenet (via SABnzbd). All media
is automatically categorized and served on the network via Plex Media Server.

All services are run as Docker containers managed via Docker Compose.

The remainder of this guide assumes a server running a Debian-based operating
system. My personal setup is running Xubuntu 22.04

## Prerequisites

### Install Docker engine

Install using the convenience script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh [--dry-run]
```

Manual steps:

1. [Install using the apt repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
1. [Linux post-install](https://docs.docker.com/engine/install/linux-postinstall/)

### Configure remote desktop (optional)

Install and configure `xrdp`

```bash
sudo apt update && sudo apt install xrdp
sudo systemctl enable xrdp
sudo ufw allow 3389/tcp
```

Install a Microsoft Remote Desktop client application

- [Microsoft Remote Desktop from the Mac AppStore](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12)
- [Microsoft Remote Desktop on Windows](https://apps.microsoft.com/store/detail/9WZDNCRFJ3PS?hl=en-us&gl=US&rtc=1)

## Set up services via Docker Compose

### Obtain VPN configuration file (optional)

**Note:** To disable using a VPN for qBittorrent connections, set
`VPN_ENABLED=no` for the `qbittorrentvpn` service in `docker-compose.yml`.

In order to use the VPN feature of the
[qBittorrentvpn](https://hub.docker.com/r/dyonr/qbittorrentvpn) image, either
an OpenVPN or Wireguard configuration must be made available at the
`${ROOT}/config` directory.

- For OpenVPN, place the `.ovpn` file from your VPN provider in the `/config/openvpn` directory.
- For Wireguard, place a configuration file named `wg0.conf` in the `/config/wireguard` directory.
  - If using privateinternetaccess VPN, a config file is not provided and must
    be generated. I used [this repository](https://github.com/hsand/pia-wg#linux-debianubuntu)
    to generate a configuration file. Once generated, ensure the output file is named
    `wg0.conf`, then copy it to the correct location.

### Start the services

```bash
git clone git@github.com:nbn22385/htpc-docker.git
cd htpc-docker
docker compose up -d
```

### Access web UI for services

Once all services are running, you can access each service's web UI using the
URLS below:

| Service     | URL                               |
| ----------- | --------------------------------- |
| Plex        | http://`<server-ip>`:32400/web    |
| qBitTorrent | http://`<server-ip>`:8080         |
| SabNZBD     | http://`<server-ip>`:8081/sabnzbd |

## Helpful commands

View logs for one or more services:

```bash
docker compose logs [service-name]
```

Restart services and recreate volumes with recent updates:

```bash
docker-compose up --renew-anon-volumes|-V
```

## Troubleshooting

### qBittorrent: Can't access web UI from the netowrk

I was able to restore access by running this command after starting services:

```bash
sudo iptables -t mangle -F
```
