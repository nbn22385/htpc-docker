# Home media server

**Plex / qBittorrent + VPN / SABnzbd / Radarr / Sonarr / Prowlarr / Bazarr**

* [Overview](#overview)
* [Prerequisites](#prerequisites)
  + [Install Docker engine](#install-docker-engine)
  + [Install SSH server](#install-ssh-server)
  + [Enable remote desktop](#enable-remote-desktop)
* [Set up directories](#set-up-directories)
* [Set up services via Docker Compose](#set-up-services-via-docker-compose)
  + [VPN configuration](#vpn-configuration)
  + [Start the services](#start-the-services)
  + [Access web UI for services](#access-web-ui-for-services)
  + [Manual service configuration](#manual-service-configuration)
* [Helpful commands](#helpful-commands)
* [Troubleshooting](#troubleshooting)
* [Additional notes](#additional-notes)

## Overview

This setup provides the ability to download media using BitTorrent (via
qBittorrent, with optional VPN support) and/or Usenet (via SABnzbd). All media
is automatically categorized and served on the network via Plex Media Server.

All services in this guide are run in Docker containers managed via Docker
Compose.

| Service     | Description                                                        |
| ----------- | ------------------------------------------------------------------ |
| Plex        | Organizes media and streams to smart devices                       |
| qBitTorrent | Torrent download client                                            |
| SABnzbd     | Usenet download client                                             |
| Radarr      | Movie collection manager, integrates with qBittorrent/SABnzbd      |
| Sonarr      | TV show collection manager, integrates with qBittorrent/SABnzbd    |
| Prowlarr    | Manages Torrent and Usenet indexers, integrates with Radarr/Sonarr |
| Bazarr      | Manages and downloads subtitles, integrates with Radarr/Sonarr     |

The remainder of this guide assumes a server running a Debian-based operating
system. My current setup is a 2013 HP Pavillion G6 with an Intel Core i5-3230M
and 6GB of RAM running Xubuntu 22.04.

## Prerequisites

* [Install Docker engine](#install-docker-engine)
* [Install SSH server](#install-ssh-server)
* [Enable remote desktop](#enable-remote-desktop)

### Install Docker engine

Install using the convenience script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh [--dry-run]
```

Or use the manual steps:

1. [Install using the apt repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
1. [Linux post-install](https://docs.docker.com/engine/install/linux-postinstall/)

### Install SSH server

To allow remote terminal access via SSH, install and configure `openssh` on the
host.

```bash
# install
sudo apt install  openssh-server
# enable service
sudo systemctl enable ssh --now
# start service
sudo systemctl start ssh
```

Test the SSH connection by logging in from another computer

```bash
ssh <host-username>@<host-ip>
```

### Enable remote desktop

**Optional**

To allow remote desktop access to the server from another computer, install and
configure `xrdp` on the host.

```bash
sudo apt update && sudo apt install xrdp
sudo systemctl enable xrdp
sudo ufw allow 3389/tcp
```

Install the Microsoft Remote Desktop application on any client computers you
with to connect from.

- Mac: [Microsoft Remote Desktop](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12)
- Windows: [Microsoft Remote Desktop](https://apps.microsoft.com/store/detail/9WZDNCRFJ3PS?hl=en-us&gl=US&rtc=1)

## Set up directories

Run the `setup.sh` script on the host to create the pre-determined directory
structure with the correct permissions. These folders will be used as volume
mounts for the Docker containers, and be referenced in each service's settings.

```bash
git clone git@github.com:nbn22385/htpc-docker.git
cd htpc-docker
./setup.sh
```

<details>
<summary>Expand to see the resulting folder structure</summary>

### The resulting directory structure for service configuration files:

```
/config
├── bazarr
├── plex
├── prowlarr
├── qbittorrent
├── radarr
├── sabnzbd
└── sonarr
```

### The resulting directory structure for data/media files:

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

</details>

## Set up services via Docker Compose

### VPN configuration

**Optional**

**Note:** To disable use of a VPN for qBittorrent connections, remove the
`network_mode` line from the `qbittorrent` service in `docker-compose.yml`.
Configuration updates will need to be made to prowlarr, radarr, and sonarr
download client settings, namely pointing the server to `qbittorrent`, rather
than `vpn`.

In order to use the Wireguard docker image, a Wireguard configuration file must
exist on the host as `/config/wireguard/wg0.cfg`.

- If using the Private Internet Access (PIA) VPN, a config file is not provided
  and must be generated. I used the instructions in
  [this repository](https://github.com/hsand/pia-wg#linux-debianubuntu)
  to generate a configuration file. Once generated, ensure the output file is
  named `wg0.conf`, then copy it to the directory noted above.

### Start the services

```bash
cd /path/to/htpc-docker
docker compose up -d
```

### Access web UI for services

Once all services are running, you can access each service's web UI using the
URLs below:

| Service     | Role             | URL                               |
| ----------- | ---------------- | --------------------------------- |
| Plex        | Media server     | http://`<server-ip>`:32400/web    |
| qBitTorrent | Torrent client   | http://`<server-ip>`:8080         |
| SABnzbd     | Usenet client    | http://`<server-ip>`:8081/sabnzbd |
| Radarr      | Movie manager    | http://`<server-ip>`:7878         |
| Sonarr      | TV show manager  | http://`<server-ip>`:8989         |
| Prowlarr    | Indexer manager  | http://`<server-ip>`:9696         |
| Bazarr      | Subtitle manager | http://`<server-ip>`:6767         |

### Manual service configuration

Settings must be manually configured for each service to properly use the
directory structure we set up, as well as adjust other behaviors and
integrations. I have listed the most important settings below, but adjust
anything else as needed.

* [Plex](#plex)
* [qBittorrent](#qbittorrent)
* [SABnzbd](#sabnzbd)
* [Radarr](#radarr)
* [Sonarr](#sonarr)
* [Prowlarr](#prowlarr)
* [Bazarr](#bazarr)

#### Plex

These custom settings are adapted from [TRaSH Guide for
Plex](https://trash-guides.info/Plex/Tips/Plex-media-server/).

<details>
<summary>Custom settings</summary>

- `Settings`
  - `General`
    - :white_square_button: Send crash reports to Plex
    - :white_square_button: Enable Plex Media Server debug logging
  - `Remote Access` (Optional)
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
        - Password: [generate a Google app password](https://myaccount.google.com/apppasswords)
  - `Connection`
    - Peer connection protocol: **TCP**
  - `Speed`
    - `Global Rate Limits`
      - Set limits here if desired
  - `WebUI`
    - :ballot_box_with_check: Bypass authentication for clients on localhost
    - :ballot_box_with_check: Bypass authentication for clients in whitelisted IP subnets
      - Example: 192.168.1.0/24
    - :ballot_box_with_check: (Optional) Use alternative WebUI
      - [VueTorrent](https://github.com/WDaan/VueTorrent#manual) already exists
        in the container. To use it, set this path to `/vuetorrent`.
  - `Tags & Categories`
    - Add category `movies` with save path `/data/torrents/movies`
    - Add category `tv` with save path `/data/torrents/tv`
  - `Advanced`
    - Network Interface: **wg0** (this is the Wireguard interface)

Click the :floppy_disk: icon to apply the changes. Then (optionally) apply the custom VueTorrent settings:

  - `Settings`
    - `VueTorrent`
      - Copy/paste the following code and click the `Import Settings` button
          ```json
          {"sort_options":{"isCustomSortEnabled":true,"sort":"priority","reverse":false,"filter":null,"category":null,"tag":null,"tracker":null},"webuiSettings":{"lang":"en","darkTheme":true,"showFreeSpace":true,"showSpeedGraph":true,"showSessionStat":true,"showAlltimeStat":true,"showCurrentSpeed":true,"showTrackerFilter":false,"showSpeedInTitle":false,"deleteWithFiles":false,"title":"Default","rightDrawer":false,"topPagination":false,"paginationSize":15,"dateFormat":"DD/MM/YYYY, HH:mm:ss","openSideBarOnStart":false,"showShutdownButton":false,"useBitSpeed":false,"useBinaryUnits":false,"refreshInterval":2000,"contentInterval":5000,"torrentPieceCountRenderThreshold":5000,"busyDesktopTorrentProperties":[{"name":"Size","active":true},{"name":"Progress","active":true},{"name":"DownloadSpeed","active":true},{"name":"UploadSpeed","active":true},{"name":"Downloaded","active":true},{"name":"SavePath","active":false},{"name":"Uploaded","active":true},{"name":"ETA","active":true},{"name":"Peers","active":true},{"name":"Seeds","active":true},{"name":"Status","active":true},{"name":"Ratio","active":false},{"name":"Tracker","active":false},{"name":"Category","active":true},{"name":"Tags","active":false},{"name":"AddedOn","active":false},{"name":"Availability","active":false},{"name":"LastActivity","active":false},{"name":"CompletedOn","active":false},{"name":"AmountLeft","active":false},{"name":"ContentPath","active":false},{"name":"DownloadedSession","active":false},{"name":"DownloadLimit","active":false},{"name":"DownloadPath","active":false},{"name":"Hash","active":false},{"name":"InfoHashV1","active":false},{"name":"InfoHashV2","active":false},{"name":"SeenComplete","active":false},{"name":"TimeActive","active":false},{"name":"TotalSize","active":false},{"name":"TrackersCount","active":false},{"name":"UploadedSession","active":false},{"name":"UploadLimit","active":false},{"name":"GlobalSpeed","active":false},{"name":"GlobalVolume","active":false}],"doneDesktopTorrentProperties":[{"name":"Size","active":true},{"name":"Progress","active":true},{"name":"DownloadSpeed","active":true},{"name":"UploadSpeed","active":true},{"name":"Downloaded","active":true},{"name":"SavePath","active":false},{"name":"Uploaded","active":true},{"name":"ETA","active":true},{"name":"Peers","active":true},{"name":"Seeds","active":true},{"name":"Status","active":true},{"name":"Ratio","active":false},{"name":"Tracker","active":false},{"name":"Category","active":true},{"name":"Tags","active":false},{"name":"AddedOn","active":false},{"name":"Availability","active":false},{"name":"LastActivity","active":false},{"name":"CompletedOn","active":false},{"name":"AmountLeft","active":false},{"name":"ContentPath","active":false},{"name":"DownloadedSession","active":false},{"name":"DownloadLimit","active":false},{"name":"DownloadPath","active":false},{"name":"Hash","active":false},{"name":"InfoHashV1","active":false},{"name":"InfoHashV2","active":false},{"name":"SeenComplete","active":false},{"name":"TimeActive","active":false},{"name":"TotalSize","active":false},{"name":"TrackersCount","active":false},{"name":"UploadedSession","active":false},{"name":"UploadLimit","active":false},{"name":"GlobalSpeed","active":false},{"name":"GlobalVolume","active":false}],"busyMobileCardProperties":[{"name":"Status","active":true},{"name":"Tracker","active":false},{"name":"Category","active":true},{"name":"Tags","active":false},{"name":"Size","active":true},{"name":"Progress","active":true},{"name":"ProgressBar","active":true},{"name":"Ratio","active":false},{"name":"Uploaded","active":false},{"name":"ETA","active":true},{"name":"Seeds","active":true},{"name":"Peers","active":true},{"name":"DownloadSpeed","active":true},{"name":"UploadSpeed","active":true}],"doneMobileCardProperties":[{"name":"Status","active":true},{"name":"Tracker","active":false},{"name":"Category","active":true},{"name":"Tags","active":false},{"name":"Size","active":true},{"name":"Progress","active":true},{"name":"ProgressBar","active":true},{"name":"Ratio","active":false},{"name":"Uploaded","active":false},{"name":"ETA","active":true},{"name":"Seeds","active":true},{"name":"Peers","active":true},{"name":"DownloadSpeed","active":true},{"name":"UploadSpeed","active":true}]},"authenticated":true}
          ```

</details>

#### SABnzbd

<details>
  <summary>Custom settings</summary>

  TBD

</details>

#### Radarr

These custom settings are adapted from [TRaSH Guide for
Radarr](https://trash-guides.info/Radarr/).

<details>
  <summary>Custom settings</summary>
  
- `Settings`
  - `Media Management`
    - :ballot_box_with_check: Rename Movies
    - :ballot_box_with_check: Replace Illegal Characters
    - `Root Folders`
      - Add an entry for `/data/media/movies`
  - `Indexers`
    - These should auto-import once Prowlarr is set up
  - `Download Clients`
    - Click `+` and select `qBittorrent`
      - Host: **wireguard**
      - Username/Password: Use qbittorrent credentials
  - `Import Lists` (Optional, allows initiating downloads via the Plex Discover
    interface)
    - Click `+` and select `Plex Watchlist`
    - :ballot_box_with_check: Enable
    - :ballot_box_with_check: Enable Automatic Add
    - Monitor: select `None` to manually manage files in Radarr, otherwise
      leave default value
    - :ballot_box_with_check: Search on Add: enable to have Radarr automatically
      search for movie, otherwise leave default value
    - Quality Profile: select desired profile
    - Authenticate with Plex.tv: click button to authenticate
      - **Note**: Clicking `Test` will produce a warning if your Plex watchlist
        contains no movies
    - Click `Save`

</details>

#### Sonarr

These custom settings are adapted from [TRaSH Guide for
Sonarr](https://trash-guides.info/Sonarr/).

<details>
  <summary>Custom settings</summary>
  
- `Settings`
  - `Media Management`
    - :ballot_box_with_check: Rename Episodes
    - :ballot_box_with_check: Replace Illegal Characters
    - `Root Folders`
      - Add an entry for `/data/media/tv`
  - `Indexers`
    - These should auto-import once Prowlarr is set up
  - `Download Clients`
    - Click `+` and select `qBittorrent`
      - Host: **wireguard**
      - Username/Password: Use qbittorrent credentials
  - `Import Lists` (Optional, allows initiating downloads via the Plex Discover
    interface)
    - Click `+` and select `Plex Watchlist`
    - :ballot_box_with_check: Enable Automatic Add
    - Monitor: select `None` to manually manage files in Sonarr, otherwise
      leave default value
    - Quality Profile: select desired profile
    - Authenticate with Plex.tv: click button to authenticate
      - **Note**: Clicking `Test` will produce a warning if your Plex watchlist
        contains no shows
    - Click `Save`

</details>

#### Prowlarr

These custom settings are adapted from [Servarr Guide for
Prowlarr](https://wiki.servarr.com/prowlarr/quick-start-guide).

<details>
<summary>Custom settings</summary>

- `Indexers`
  - `Add Indexer`
    - Search for an indexer and add it. Keep default settings.
- `Settings`
  - `Apps`
    - Click `+` and select `Radarr`
      - Prowlarr server: **http://prowlarr:9696**
      - Radarr server: **http://radarr:7878**
      - ApiKey: **Radarr API key from its `Settings > General` page**
    - Click `+` and select `Sonarr`
      - Prowlarr server: **http://prowlarr:9696**
      - Sonarr server: **http://sonarr:8989**
      - ApiKey: **Sonarr API key from its `Settings > General` page**
  - `Download Clients`
    - Click `+` and select `qBittorrent`
      - Host: **wireguard**
      - Username/Password: Use qbittorrent credentials
  - `General`
    - `Security`
      - Authentication Required: **Disabled for Local Addresses**

</details>

#### Bazarr

These custom settings are adapted from [TRaSH Guide for
qBittorrent](https://trash-guides.info/Bazarr/Setup-Guide/).

<details>
  <summary>Custom settings</summary>
  
- `Settings`
  - `Languages`
    - `Subtitles Language > Languages Filter`
      - Add `English` to the list
    - `Language Profiles`
      - Add a new profile and choose the English language
    - `Default Settings`
      - :ballot_box_with_check: Series
        - Profile: **English profile name**
      - :ballot_box_with_check: Movies
        - Profile: **English profile name**
  - `Providers`
    - Add: **OpenSubtitles.com, Embedded Subtitles, subf2m.co**
  - `Sonarr`
    - Address: **sonarr**
    - API Key: **Sonarr API key from its `Settings > General` page**
  - `Radarr`
    - Address: **radarr**
    - API Key: **Radarr API key from its `Settings > General` page**

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

* [Mounting a network share on host and Plex container](#mounting-a-network-share-on-host-and-plex-container)
* [Disable laptop suspend when lid is closed](#disable-laptop-suspend-when-lid-is-closed)
* [Restart on a schedule](#restart-on-a-schedule)

### Mounting a network share on host and Plex container

**Note**: This will result in non-optimal copying/moving due to hardlinks not
functioning across filesystems/shares.

In this example, I have an external USB hard drive connected to my router,
which is shared as an SMB share on the network. Note: I could not get the
credentials working and resorted to allowing any connection from within the
network (working to fix).

1. On the host, install `cifs` and create the directory to be used
   as the mount point

```bash
sudo apt install cifs-utils -y
sudo mkdir /mnt/elements # directory that will act as the mount point for the SMB share
```

3. Edit the fstab file to automount the network share on boot (and after network is up)

```bash
sudo vim /etc/fstab
```

```bash
# <SHARE-IP>/<DIRECTORY>  <MOUNT-POINT>   <TYPE> <OPTIONS>                <BACKUP> <FSCK>
//192.168.29.1/Elements   /mnt/elements   cifs   _netdevuid=nate,vers=1.0 0        0
```

2. In Plex, add the shared directory(s) to your library. In this example, I
   mapped the shared directory to `/elements` in the container.

```yml
plex:
  volumes:
    - /mnt/elements:/elements
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

### Restart on a schedule

I set the host PC to restart every Sunday at 4 AM with a cronjob

```bash
sudo crontab -e

# add the following line, save, and quit the editor
0 4 * * SUN /sbin/reboot

# verify the rule was saved
sudo crontab -l
```
