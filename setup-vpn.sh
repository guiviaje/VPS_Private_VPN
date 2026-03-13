#!/usr/bin/env bash
# Minimal WireGuard + wg-easy setup for a VPS.
# Run as root on the server.
#
# One-click usage from your machine:
#   1. Copy `.env.example` to `.env` and fill it in.
#   2. scp .env setup-vpn.sh root@YOUR_VPS_IP:/root/
#   3. ssh root@YOUR_VPS_IP 'bash /root/setup-vpn.sh'
#
# The script will auto-load `/root/.env` when present.
# Keep `.env` out of git.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -a
  . "${SCRIPT_DIR}/.env"
  set +a
fi

VPS_IP="${VPS_IP:?Set VPS_IP (VPS IPv4)}"
WG_EASY_PASSWORD="${WG_EASY_PASSWORD:?Set WG_EASY_PASSWORD}"

# --- Step 1: System update (run as root) ---
step1_update() {
  apt update && apt upgrade -y && apt autoremove -y
}

# --- Step 2: Create vpnadmin and harden SSH ---
# Before running step2: set VPNADMIN_SSH_PUBKEY and test login as vpnadmin from another terminal.
step2_user_and_ssh() {
  if ! id vpnadmin &>/dev/null; then
    adduser --gecos '' vpnadmin
    usermod -aG sudo vpnadmin
  fi
  mkdir -p /home/vpnadmin/.ssh
  chmod 700 /home/vpnadmin/.ssh
  echo "${VPNADMIN_SSH_PUBKEY:?Set VPNADMIN_SSH_PUBKEY}" > /home/vpnadmin/.ssh/authorized_keys
  chmod 600 /home/vpnadmin/.ssh/authorized_keys
  chown -R vpnadmin:vpnadmin /home/vpnadmin/.ssh

  echo "→ From your Mac, run: ssh vpnadmin@${VPS_IP}"
  if [[ -t 0 ]]; then
    read -p "Press Enter after vpnadmin SSH works..."
  fi

  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  systemctl restart sshd
}

# --- Step 3: UFW ---
step3_ufw() {
  ufw allow OpenSSH
  ufw allow 51820/udp
  ufw allow 51821/tcp
  ufw --force enable
  ufw status
}

# --- Step 4: Docker + wg-easy ---
step4_docker_wgeasy() {
  apt install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Run as vpnadmin's group so data is under their home if we use ~/.wg-easy later
  WG_DATA="${WG_DATA:-/root/.wg-easy}"
  mkdir -p "$WG_DATA"

  docker run -d \
    --name wg-easy \
    -e WG_HOST="$VPS_IP" \
    -e PASSWORD="$WG_EASY_PASSWORD" \
    -v "$WG_DATA:/etc/wireguard" \
    -p 51820:51820/udp \
    -p 51821:51821/tcp \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
    --restart unless-stopped \
    weejewel/wg-easy

  echo "→ wg-easy UI: http://${VPS_IP}:51821"
}

# --- Main: run all steps in order (or source and run step-by-step) ---
if [[ "${1:-}" == "only" ]]; then
  step1_update
  echo "Step 1 done. Export VPNADMIN_SSH_PUBKEY then run: bash $0 only2"
  exit 0
fi
if [[ "${1:-}" == "only2" ]]; then
  step2_user_and_ssh
  exit 0
fi
if [[ "${1:-}" == "only3" ]]; then
  step3_ufw
  exit 0
fi
if [[ "${1:-}" == "only4" ]]; then
  step4_docker_wgeasy
  exit 0
fi

# Full run: set VPS_IP, WG_EASY_PASSWORD, VPNADMIN_SSH_PUBKEY first.
# Safer: run step-by-step with only/only2/only3/only4 and test vpnadmin login before step2 locks root.
step1_update
step2_user_and_ssh
step3_ufw
step4_docker_wgeasy
