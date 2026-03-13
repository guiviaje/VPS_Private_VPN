# Contabo: create a VPS and deploy the private VPN

Step-by-step instructions for an agent (or human) to **provision a VPS on Contabo** and then **deploy the repo’s one-click VPN script** on it.

---

## Recommended VPS (generic)

For a private WireGuard VPN you need a **small Ubuntu VPS** with:

- **vCPU:** 1 or more  
- **RAM:** 1 GB or more  
- **Storage:** 20 GB or more (SSD or NVMe preferred)  
- **Network:** 1 dedicated public IPv4, outbound traffic suitable for normal use  
- **OS:** Ubuntu 22.04 or 24.04 LTS (64-bit)

On Contabo, a suitable product is the **Cloud VPS** line (not the legacy “VPS” line). A good example tier is **Cloud VPS 20 SSD** (or the current equivalent small/medium tier with Ubuntu and a dedicated IP). Pick the smallest tier that meets the requirements above if you want to minimise cost.

---

## Step 1: Contabo account and order

1. Go to [contabo.com](https://contabo.com).
2. Create an account or sign in.
3. Open **Cloud VPS** (not “VPS”).
4. Choose a **tier** that meets the recommended specs (e.g. **Cloud VPS 20 SSD** or similar).
5. Choose **region** (e.g. closest to the user or to the desired VPN exit location).
6. Choose **OS:** **Ubuntu 24.04** (64-bit) or Ubuntu 22.04 LTS.
7. Complete the order (payment, etc.).
8. From the **order confirmation email** or the **Contabo customer panel**, note:
   - **Dedicated IPv4** of the VPS  
   - **Root password** for the VPS  

Keep these for the next steps.

---

## Step 2: Prepare the deploy environment (user’s machine)

The user (or agent) needs the repo and a filled `.env` on the machine that will run `scp` and `ssh`.

1. **Clone the repo** (if not already present):
   ```bash
   git clone https://github.com/guiviaje/VPS_Private_VPN.git
   cd VPS_Private_VPN
   ```

2. **Create and fill `.env`:**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and set:
   - `VPS_IP` = the **dedicated IPv4** from Step 1  
   - `WG_EASY_PASSWORD` = a **strong password** for the wg-easy web UI  
   - `VPNADMIN_SSH_PUBKEY` = the **contents of the user’s SSH public key** (e.g. `cat ~/.ssh/id_ed25519.pub` or `cat ~/.ssh/id_rsa.pub`)  

   Do not commit `.env`; it is ignored by git.

3. Ensure **SSH access** to the VPS works (e.g. `ssh root@VPS_IP`). If the provider only gave a password, use it to log in; the script will still work.

---

## Step 3: Copy script and env to the VPS

From the repo directory on the user’s machine:

```bash
scp .env setup-vpn.sh root@VPS_IP:/root/
```

Use the actual `VPS_IP` value (or ensure `VPS_IP` is set in the environment and use `$VPS_IP`). If SSH uses a key, it will be used; if it asks for a password, use the root password from Step 1.

---

## Step 4: Run the one-click install on the VPS

```bash
ssh root@VPS_IP 'bash /root/setup-vpn.sh'
```

The script will:

- Update the system  
- Create user `vpnadmin` and install the SSH public key from `.env`  
- Disable root login and password SSH login  
- Enable UFW (SSH, WireGuard UDP 51820, wg-easy TCP 51821)  
- Install Docker and run wg-easy  

When it finishes, root SSH will be disabled; further access is via `vpnadmin`.

---

## Step 5: After deploy

1. **SSH as vpnadmin:**
   ```bash
   ssh vpnadmin@VPS_IP
   ```

2. **Open the wg-easy web UI** in a browser:
   ```text
   http://VPS_IP:51821
   ```
   Log in with the password set in `.env` as `WG_EASY_PASSWORD`.

3. **Add VPN clients** in the UI (e.g. “laptop”, “phone”), download the config or QR code, and import into the WireGuard app on each device.

4. **Connect** the WireGuard client; traffic will use the VPS’s dedicated IP.

---

## Optional: run the script in stages

If the user wants to test `vpnadmin` login before root is disabled, run the script step by step:

```bash
ssh root@VPS_IP 'bash /root/setup-vpn.sh only'
ssh root@VPS_IP 'bash /root/setup-vpn.sh only2'
ssh root@VPS_IP 'bash /root/setup-vpn.sh only3'
ssh root@VPS_IP 'bash /root/setup-vpn.sh only4'
```

After `only`, test `ssh vpnadmin@VPS_IP` before continuing.

---

## Summary for the agent

1. Order a Contabo Cloud VPS (Ubuntu 24.04 or 22.04), tier meeting the recommended specs (e.g. Cloud VPS 20 SSD).  
2. Obtain the VPS **IPv4** and **root password**.  
3. On the user’s machine: clone repo, `cp .env.example .env`, set `VPS_IP`, `WG_EASY_PASSWORD`, `VPNADMIN_SSH_PUBKEY`.  
4. `scp .env setup-vpn.sh root@VPS_IP:/root/`  
5. `ssh root@VPS_IP 'bash /root/setup-vpn.sh'`  
6. Tell the user: SSH with `vpnadmin@VPS_IP`, open `http://VPS_IP:51821`, add clients, and use the WireGuard app.
