#!/bin/bash

# =========================================================================
#          ✨ SoftEther VPN Server Auto Installer ✨
#
#   An all-in-one script to install, update, or uninstall SoftEther VPN.
#   Compatible with both systemd and SysV init systems.
#
#   Requires root privileges to run.
# =========================================================================

# --- Configuration ---
INSTALL_PATH="/opt/softether"
SERVICE_NAME="softether"
GITHUB_REPO="SoftEtherVPN/SoftEtherVPN_Stable"

# --- Style ---
C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[1;33m'; C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'; C_BOLD='\033[1m'; C_NC='\033[0m'

# --- Global Variables ---
INIT_SYSTEM=""
PKG_MANAGER=""
PKG_INSTALL_CMD=""
SERVICE_FILE=""
OS_NAME=""
OS_VERSION=""
CPU_ARCH=""

# --- Initial Check ---
if [[ "$EUID" -ne 0 ]]; then
  echo -e "\n${C_RED}${C_BOLD}❌ Error: This script must be run as root.${C_NC}\n"; exit 1
fi

# --- System Detection Functions ---

get_system_info() {
    CPU_ARCH=$(uname -m)
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
    else
        OS_NAME="Unknown"
        OS_VERSION="N/A"
    fi
}

detect_init_system() {
    if [[ -d /run/systemd/system ]]; then
        INIT_SYSTEM="systemd"
        SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
    else
        INIT_SYSTEM="sysv"
        SERVICE_FILE="/etc/init.d/${SERVICE_NAME}"
    fi
}

detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL_CMD="sudo apt-get update && sudo apt-get install -y build-essential curl jq"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL_CMD="sudo dnf groupinstall -y 'Development Tools' && sudo dnf install -y curl jq"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL_CMD="sudo yum groupinstall -y 'Development Tools' && sudo yum install -y curl jq"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL_CMD="sudo pacman -S --noconfirm base-devel curl jq"
    else
        PKG_MANAGER="unknown"
    fi
}

# --- Helper Functions ---
press_enter_to_continue() {
    echo -e "\n${C_YELLOW}Press [Enter] to return to the menu...${C_NC}"; read -r
}

# --- Core Logic Functions ---

show_menu() {
    clear
    local datetime=$(date '+%A, %B %d, %Y %T %Z')
    echo -e "${C_CYAN}===================================================${C_NC}"
    echo -e "${C_CYAN}  ${C_BOLD}SoftEther VPN Server Auto Installer${C_NC}"
    echo -e "${C_CYAN}===================================================${C_NC}"
    echo -e "${C_YELLOW}  OS:          ${OS_NAME} ${OS_VERSION}${C_NC}"
    echo -e "${C_YELLOW}  Arch:        ${CPU_ARCH}${C_NC}"
    echo -e "${C_YELLOW}  Init System: ${INIT_SYSTEM}${C_NC}"
    echo -e "${C_YELLOW}  System Time: ${datetime}${C_NC}"
    echo -e "${C_CYAN}---------------------------------------------------${C_NC}"
    echo -e "  ${C_GREEN}${C_BOLD}1.${C_NC} Install or Update Server"
    echo -e "  ${C_RED}${C_BOLD}2.${C_NC} Uninstall Server"
    echo -e "  ${C_BLUE}${C_BOLD}3.${C_NC} Exit Script"
    echo -e "${C_CYAN}---------------------------------------------------${C_NC}"
}

install_softether() {
    set -e
    echo -e "${C_GREEN}${C_BOLD}🚀 Starting SoftEther VPN Server installation...${C_NC}"
    echo "🔎 Checking dependencies..."
    for cmd in curl jq gcc make; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${C_RED}🚨 A required command is missing.${C_NC}"
            if [[ "$PKG_MANAGER" != "unknown" ]]; then
                echo -e "Please run the following command to install dependencies:\n${C_YELLOW}${PKG_INSTALL_CMD}${C_NC}"
            fi
            exit 1
        fi
    done
    echo "✅ Dependencies satisfied."

    case "$CPU_ARCH" in x86_64) ARCH_STRING="x64-64bit" ;; aarch64) ARCH_STRING="arm64-64bit" ;; armv7l) ARCH_STRING="arm_eabi-32bit" ;; i686|i386) ARCH_STRING="x86-32bit" ;; *) echo -e "${C_RED}❌ Unsupported architecture: $CPU_ARCH${C_NC}"; exit 1 ;; esac
    echo "✅ Detected architecture: $CPU_ARCH ($ARCH_STRING)"

    echo "📡 Finding latest release..."
    API_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
    DOWNLOAD_URL=$(curl -s "$API_URL" | jq -r --arg ARCH_STRING "$ARCH_STRING" '.assets[] | .browser_download_url | select(contains("vpnserver") and contains("linux") and contains($ARCH_STRING))')
    if [[ -z "$DOWNLOAD_URL" ]]; then echo -e "${C_RED}❌ Could not find a download URL.${C_NC}"; exit 1; fi
    echo "✅ Download URL found."

    echo "📥 Downloading SoftEther..."
    TEMP_FILE=$(mktemp)
    wget -q --show-progress -O "$TEMP_FILE" "$DOWNLOAD_URL"
    
    if [[ -f "$SERVICE_FILE" ]]; then echo "⚠️ Existing service found. Stopping it for the update..."; case "$INIT_SYSTEM" in systemd) systemctl stop "${SERVICE_NAME}";; sysv) "${SERVICE_FILE}" stop;; esac; fi

    echo "📦 Extracting files to ${INSTALL_PATH}..."
    mkdir -p "$INSTALL_PATH"
    tar -xzf "$TEMP_FILE" -C "$INSTALL_PATH" --strip-components=1
    rm "$TEMP_FILE"; cd "$INSTALL_PATH"

    echo "⚙️  Compiling server..."; printf "1\n1\n1\n" | make > /dev/null 2>&1
    chmod 700 vpnserver vpncmd && chmod 600 .
    echo "✅ Compilation complete."

    echo "🔧 Creating and enabling service for ${INIT_SYSTEM}..."
    case "$INIT_SYSTEM" in
        systemd)
            cat > "$SERVICE_FILE" <<EOL
[Unit]
Description=SoftEther VPN Server
After=network.target
[Service]
Type=forking
ExecStart=$INSTALL_PATH/vpnserver start
ExecStop=$INSTALL_PATH/vpnserver stop
WorkingDirectory=$INSTALL_PATH
Restart=always
User=root
Group=root
[Install]
WantedBy=multi-user.target
EOL
            systemctl daemon-reload
            systemctl enable "${SERVICE_NAME}.service"
            systemctl start "${SERVICE_NAME}.service"
            ;;
        sysv)
            cat > "$SERVICE_FILE" <<EOL
#!/bin/sh
### BEGIN INIT INFO
# Provides:          ${SERVICE_NAME}
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start SoftEther VPN Server
### END INIT INFO
DAEMON=${INSTALL_PATH}/vpnserver
NAME=${SERVICE_NAME}
case "\$1" in
  start) \$DAEMON start ;;
  stop) \$DAEMON stop ;;
  restart) \$DAEMON stop; sleep 2; \$DAEMON start ;;
  *) echo "Usage: /etc/init.d/\$NAME {start|stop|restart}"; exit 1 ;;
esac
exit 0
EOL
            chmod +x "$SERVICE_FILE"
            if command -v update-rc.d &>/dev/null; then update-rc.d "$SERVICE_NAME" defaults; elif command -v chkconfig &>/dev/null; then chkconfig --add "$SERVICE_NAME"; fi
            "$SERVICE_FILE" start
            ;;
    esac
    echo "✅ Service started."

    echo -e "\n${C_GREEN}${C_BOLD}🎉 Success! SoftEther VPN Server is installed and running.${C_NC}"
    echo -e "   - To configure:     ${C_YELLOW}${INSTALL_PATH}/vpncmd${C_NC}"
    
    echo -e "\n${C_CYAN}🔎 Retrieving access information...${C_NC}"; sleep 2
    URLS=""
    case "$INIT_SYSTEM" in
        systemd)
            JOURNAL_LOG=$(journalctl -u "${SERVICE_NAME}" --no-pager -n 20)
            URLS=$(echo "${JOURNAL_LOG}" | grep -oP 'https?://[^\s]+/')
            ;;
        sysv)
            LATEST_LOG=$(find "${INSTALL_PATH}/server_log" -name "*.log" -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
            if [[ -n "$LATEST_LOG" ]]; then
                URLS=$(grep -oP 'https?://[^\s]+/' "${LATEST_LOG}" || true)
            fi
            ;;
    esac

    if [[ -n "${URLS:-}" ]]; then
        echo -e "${C_GREEN}${C_BOLD}✅ Admin Console URLs reported by SoftEther:${C_NC}"
        echo "${URLS}" | sort -u | while read -r url; do
            if [[ "$url" =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} || "$url" =~ "localhost" ]]; then echo -e "   - ${C_YELLOW}${url}${C_NC}"; fi
        done
        echo -e "\n   ${C_BOLD}Important Note:${C_NC} The IP address above may be a local/internal IP."
        echo "   If connecting from outside the network, use your server's correct public IP address."
    else
        echo -e "   ${C_YELLOW}Could not automatically detect Admin Console URL from the logs.${C_NC}"
    fi
    set +e
}

uninstall_softether() {
    if [[ ! -d "$INSTALL_PATH" && ! -f "$SERVICE_FILE" ]]; then echo -e "\n${C_YELLOW}🔎 SoftEther not installed.${C_NC}"; return; fi
    set -e
    echo -e "${C_YELLOW}${C_BOLD}\nThis will completely remove SoftEther VPN Server.${C_NC}"
    read -p "Are you sure? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then echo -e "${C_BLUE}🚫 Aborted.${C_NC}"; set +e; return; fi

    echo "🗑️  Starting uninstallation..."
    echo "➡️ Stopping service '${SERVICE_NAME}'..."
    case "$INIT_SYSTEM" in
        systemd)
            if systemctl is-active --quiet "${SERVICE_NAME}"; then systemctl stop "${SERVICE_NAME}"; fi
            ;;
        sysv)
            if [[ -f "$SERVICE_FILE" ]]; then "$SERVICE_FILE" stop &>/dev/null || true; fi
            ;;
    esac

    echo -n "   Waiting for process to terminate..."
    for _ in {1..5}; do if ! pgrep -f "vpnserver" > /dev/null; then echo -e " ${C_GREEN}Success.${C_NC}"; break; fi; echo -n "."; sleep 1; done
    if pgrep -f "vpnserver" > /dev/null; then echo -e "\n   ${C_YELLOW}Forcing termination...${C_NC}"; pkill -9 -f "vpnserver"; sleep 1; fi
    
    echo "➡️ Removing service from startup..."
    case "$INIT_SYSTEM" in
        systemd)
            if systemctl list-units --type=service --all | grep -q "${SERVICE_NAME}.service"; then
                systemctl disable "${SERVICE_NAME}" &>/dev/null || true
            fi
            ;;
        sysv)
            if command -v update-rc.d &>/dev/null; then update-rc.d -f "$SERVICE_NAME" remove &>/dev/null || true;
            elif command -v chkconfig &>/dev/null; then chkconfig --del "$SERVICE_NAME" &>/dev/null || true; fi
            ;;
    esac

    if [[ -f "$SERVICE_FILE" ]]; then
        echo "➡️ Removing service file..."; rm -f "$SERVICE_FILE"
        if [[ "$INIT_SYSTEM" == "systemd" ]]; then systemctl daemon-reload; fi
    fi
    if [[ -d "$INSTALL_PATH" ]]; then echo "➡️ Removing installation directory..."; rm -rf "$INSTALL_PATH"; fi
    echo -e "\n${C_GREEN}${C_BOLD}✅ SoftEther VPN Server has been uninstalled.${C_NC}"; set +e
}

# --- Main Execution ---
set -u; set -o pipefail
detect_init_system
detect_package_manager
get_system_info

while true; do
    show_menu
    read -rp "$(echo -e "${C_BOLD}Enter your choice [1-3]: ${C_NC}")" choice
    case $choice in
        1) install_softether; press_enter_to_continue ;;
        2) uninstall_softether; press_enter_to_continue ;;
        3 | q | Q) echo -e "${C_BLUE}${C_BOLD}👋 Goodbye!${C_NC}"; break ;;
        *) echo -e "${C_RED}Invalid option.${C_NC}"; sleep 2 ;;
    esac
done
