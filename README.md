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

## Additional notes

### Disable laptop suspend when lid is closed

When using a laptop as a server, the system may suspend when the lid is closed.
To prevent this, make the following modification and restart the computer.

```bash
sudo vim /etc/systemd/logind.conf
```

Uncomment and edit the following lines:

```text
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
```

### qBittorrent customization

#### VueTorrent UI theme

https://github.com/WDaan/VueTorrent#manual

1. Visit the Vuetorrent [Releases](https://github.com/WDaan/VueTorrent/releases) page
1. Download the latest vuetorrent.zip
1. Unzip the downloaded file
1. Point your alternate WebUI location to the vuetorrent folder in qBittorrent settings

#### Email notifications

When a file completes downloading, you can email/SMS yourself. I used the email
address that T-Mobile provides which is translated into an SMS.

1. Open qBittorrent settings
1. Click the Downloads tab
1. Enable "Email notification upon dowload completion"
1. Fill out the fields
   1. From: <any text>
   1. To: destination email address (I used the T-Mobile sms relay <YOUR-NUMBER@tmomail.net>)
1. Enable SSL
1. Fill out Authentication
   1. Username: your email address <YOUR-EMAIL@gmail.com>
   1. Password: [generate a Google app password](https://myaccount.google.com/apppasswords)
