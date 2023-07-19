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

## Set up directories

Run the `setup.sh` script to create the host's folder structure with the
correct permissions

```bash
git clone git@github.com:nbn22385/htpc-docker.git
cd htpc-docker
./setup.sh
```

The resulting folder structure for service configuration files:

```
/config
├── plex
├── qbittorrent
├── radarr
├── sabnzbd
└── sonarr
```

The resulting folder structure for data/media files:

```
/data
├── media
│   ├── movies
│   └── tv
├── torrents
│   ├── movies
│   └── tv
└── usenet
    ├── movies
    └── tv
```

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
cd /path/to/htpc-docker
docker compose up -d
```

### Access web UI for services

Once all services are running, you can access each service's web UI using the
URLS below:

| Service     | Role             | URL                               |
| ----------- | ---------------- | --------------------------------- |
| Plex        | Media server     | http://`<server-ip>`:32400/web    |
| qBitTorrent | Torrent client   | http://`<server-ip>`:8080         |
| SabNZBD     | Usenet client    | http://`<server-ip>`:8081/sabnzbd |
| Sonarr      | TV show manager  | http://`<server-ip>`:8989         |
| Radarr      | Movie manager    | http://`<server-ip>`:7878         |
| Bazarr      | Subtitle manager | http://`<server-ip>`:6767         |

### Service configuration

#### Plex

These custom settings are adapted from [TRaSH Guide for
Plex](https://trash-guides.info/Plex/Tips/Plex-media-server/).

<details>
<summary>Custom settings</summary>

- `Settings`
  - `General`
    - :white_square_button: Send crash reports to Plex
    - :white_square_button: Enable Plex Media Server debug logging
  - `Remote Access`
    - :ballot_box_with_check: Remote access (Note: may need to forward router port 32400 to the host)
    - :ballot_box_with_check: Manually specify public port: 32400
  - `Library`
    - :ballot_box_with_check: Scan my library automatically
    - :ballot_box_with_check: Run a partial scan when changes are detected
    - :ballot_box_with_check: Run scanner tasks at a lower priority
- `Manage`
  - `Libraries`
    - `Movies`
      - `Manage Recommendations`
        - Disable any recommendations you don't want to the client screen
      - `Edit Library > Add Folders`
        - Ensure `/media/movies` is listed
    - `TV`
      - `Manage Recommendations`
        - Disable any recommendations you don't want to the client screen
      - `Edit Library > Add Folders`
        - Ensure `/media/tv` is listed
</details>

#### qBittorrent

These custom settings are adapted from [TRaSH Guide for
qBittorrent](https://trash-guides.info/Downloaders/qBittorrent/Basic-Setup/).

<details>
<summary>Custom settings</summary>

- `Settings`
  - `Downloads`
    - :ballot_box_with_check: Delete .torrent files afterwards
    - :ballot_box_with_check: Pre-allocate disk space for all files
    - Default torrent management mode: **Automatic**
    - Default save path: `/data/torrents`
    - :ballot_box_with_check: (Optional) Email notification upon download completion
      - From: "qBittorrent" (or any text)
      - To: Destination email address (I used the T-Mobile email-to-sms gateway
        <10-digit-number@tmomail.net>). Check your carrier.
      - SMTP server: smtp.gmail.com
      - :ballot_box_with_check: This server requires a secure connection (SSL)
      - `Authentication`
        - Username: <YOUR-EMAIL@gmail.com>
        - Password: [generate a Google app
          password](https://myaccount.google.com/apppasswords)
  - `Connection`
    - Peer connection protocol: **TCP**
  - `Speed`
    - `Global Rate Limits`
      - Set limits here if desired
  - `WebUI`
    - :ballot_box_with_check: (Optional) Use alternative WebUI
      - Extract [VueTorrent](https://github.com/WDaan/VueTorrent#manual) to the
        host's `/config/qBittorrent/vuetorrent` directory, then set this option
  - `Tags & Categories`
    - Add categories `movies` and `tv`
  - `Advanced`
    - Network Interface: **wg0** (this is the Wireguard interface)

</details>

#### [SABnzbd](https://trash-guides.info/Downloaders/SABnzbd/Basic-Setup/) (Usenet downloader)

<details>
  <summary>Custom settings</summary>
  
</details>

#### [Radarr](https://trash-guides.info/Radarr/) (Movie manager)

<details>
  <summary>Custom settings</summary>
  
</details>

#### [Sonarr](https://trash-guides.info/Sonarr/) (TV show manager)

<details>
  <summary>Custom settings</summary>
  
</details>

#### [Bazarr](https://trash-guides.info/Bazarr/Setup-Guide/) (Subtitle manager)

<details>
  <summary>Custom settings</summary>
  
</details>


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

### Mounting a network share on host and Plex container

In this example, I have an external USB hard drive connected to my router,
which is shared as an SMB share on the network. Note: I could not get the
credentials working and resorted to allowing any connection from within the
network (working to fix).

1. On the host, install cifs and create the folder to be used as the mount
   point

```bash
sudo apt install cifs-utils -y
sudo mkdir /mnt/elements # directory that will act as the mount point for the SMB share
```

3. Edit the fstab file to automount the network share on boot

```bash
sudo vim /etc/fstab
```

```bash
# <SHARE-IP>/<FOLDER>    <MOUNT-POINT>  <TYPE> <OPTIONS>                <BACKUP> <FSCK>
//192.168.29.1/Elements /mnt/elements   cifs   _netdevuid=nate,vers=1.0 0        0
```

2. In Plex, add the shared folder(s) to your library. In this example, I mapped
   the shared folder to `/elements` in the container.

```yml
plex:
  volumes:
    - /mnt/elements/:/elements
```

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
