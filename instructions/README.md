# Instructions for VPS providers

This folder contains **step-by-step instructions** you can give to an AI agent (or follow yourself) to automatically create a private VPN on a VPS.

Each subfolder is for a **specific VPS provider**. The agent should:

1. Use the provider-specific instructions to **provision a VPS** (account, order, region, OS, and to obtain the VPS IP and root password).
2. Then **deploy the VPN** using the root repo’s one-click script: copy `.env` and `setup-vpn.sh` to the VPS and run the script (see the repo [README](../README.md)).

## Available providers

| Provider | Path | Description |
|----------|------|-------------|
| **Contabo** | [contabo/](contabo/) | Order a Cloud VPS (Ubuntu), get IP and root password, then run the deploy script. |

## Generic requirements (any provider)

The VPS must have:

- **OS:** Ubuntu 22.04 or 24.04 LTS (64-bit).
- **Access:** Root SSH with password or SSH key.
- **Network:** One dedicated public IPv4.
- **Resources:** At least 1 vCPU, 1 GB RAM, and ~20 GB storage (enough for Docker and WireGuard). More is fine.

The repo’s script installs WireGuard + wg-easy, creates a `vpnadmin` user, hardens SSH, and opens the wg-easy web UI on port 51821.
