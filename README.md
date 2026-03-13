# VPS WireGuard Setup

**One-click self-hosted VPN · WireGuard + wg-easy on Ubuntu VPS · dedicated IP · bypass geo-blocking and LLM region restrictions**

A VPS running WireGuard is one of the simplest ways to get a **private VPN** with a **fixed, dedicated IP**—no subscription theater, no “your region is not supported.” Useful when LLM providers, streaming services, or other gatekeepers decide where you’re allowed to exist on the internet. This script gets you from zero to your own exit node in one run. The cloud is someone else’s computer; this one is yours.

Minimal script to install WireGuard + wg-easy on an Ubuntu VPS.

This repo is meant to stay shareable:
- `setup-vpn.sh`
- `.env.example`
- `README.md`
- **[instructions/](instructions/)** — Step-by-step guides (e.g. [Contabo](instructions/contabo/)) you can give to an AI agent to provision a VPS and run this script.

## Requirements

- Ubuntu VPS with a public IPv4
- Root SSH access
- A local SSH public key
- WireGuard app on the devices you want to connect

## VPS compatibility

The script is known to work on (Ubuntu, root SSH, public IPv4):

- **Contabo** — Cloud VPS 20 SSD

Any similar Ubuntu VPS with `apt` and enough resources for Docker should work. If you ran this somewhere and it didn't explode, add your provider/tier to the list—the next person would rather not discover the hard way. PRs welcome.

## Configure

Copy the example env file:

```bash
cp .env.example .env
```

Set these values:

```bash
VPS_IP=YOUR_VPS_IP
WG_EASY_PASSWORD='choose-a-strong-password'
VPNADMIN_SSH_PUBKEY='ssh-ed25519 AAAA... your@email.com'
```

Get your public key with:

```bash
cat ~/.ssh/id_ed25519.pub
```

If you use RSA:

```bash
cat ~/.ssh/id_rsa.pub
```

## One-click install

Copy the script and your local `.env` file to the server:

```bash
scp .env setup-vpn.sh root@YOUR_VPS_IP:/root/
```

Run the installer:

```bash
ssh root@YOUR_VPS_IP 'bash /root/setup-vpn.sh'
```

The script will:
- update packages
- create `vpnadmin`
- install your SSH key for `vpnadmin`
- disable root SSH login
- disable password-based SSH login
- enable UFW for SSH and WireGuard
- install Docker
- start `wg-easy`

## After install

SSH with the new admin user:

```bash
ssh vpnadmin@YOUR_VPS_IP
```

Open the web UI:

```text
http://YOUR_VPS_IP:51821
```

Create clients in wg-easy and import them into the WireGuard app.

## Optional staged run

If you want to stop before SSH hardening, run the steps manually:

```bash
ssh root@YOUR_VPS_IP 'bash /root/setup-vpn.sh only'
ssh root@YOUR_VPS_IP 'bash /root/setup-vpn.sh only2'
ssh root@YOUR_VPS_IP 'bash /root/setup-vpn.sh only3'
ssh root@YOUR_VPS_IP 'bash /root/setup-vpn.sh only4'
```

This lets you test `ssh vpnadmin@YOUR_VPS_IP` before root SSH access is disabled.

---

## To add / ideas

- **Terraform** (or similar) — provision VPS + run script so the whole stack is infra-as-code
- **Ansible playbook** — alternative to the bash script for those who prefer idempotent playbooks
- **Backup/restore** — script or doc to backup `~/.wg-easy` (or equivalent) and restore on a new box
- **Healthcheck / alerting** — optional cron or external check that the VPN endpoint is up and the WireGuard interface has peers

---

## Make this repo discoverable (when you publish on GitHub)

Set the **repository description** (About → edit) to something like:

> One-click WireGuard + wg-easy on Ubuntu VPS. Self-hosted VPN with a dedicated IP to bypass geo-blocking and LLM region restrictions. No subscription.

Add **Topics** (tags) so the repo shows up in search and in LLM/code indexes:  
`wireguard` `vpn` `vps` `ubuntu` `wg-easy` `self-hosted` `dedicated-ip` `geo-blocking` `one-click` `bash`

---

Contributions welcome from anyone who runs their own stack—Gilfoyle types, indie devs, and non-corporate agents preferred. No pitch decks required.
