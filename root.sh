#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#                    ROOTSUNNYLAB PROOT
#                   Ubuntu 22.04 LTS VM
#            Fast • Stable • Optimized • Modern
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  A feature‑rich proot environment manager with
#  backup, restore, update, package installer,
#  custom branding and interactive menu system.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -euo pipefail

############################################################
# ROOT DIRECTORY & ENVIRONMENT
############################################################

ROOTSUNNYLAB_DIR="$(pwd)"
export PATH="$PATH:$HOME/.local/usr/bin"

############################################################
# SETTINGS
############################################################

MAX_RETRIES=50
TIMEOUT=10
ROOTFS_URL_UBUNTU="https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.5-base-%%ARCH%%.tar.gz"
PROOT_URL="https://proot.gitlab.io/proot/bin/proot"
INSTALL_FLAG_FILE="$ROOTSUNNYLAB_DIR/.rootsunnylab_installed"

# User configurable
ROOT_PASSWORD="root"               # change if you like
CREATE_USER=""                     # set to a username to create a non‑root user

############################################################
# COLORS & STYLE
############################################################

RESET='\033[0m'
BOLD='\033[1m'

# Basic colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'

# ROOTSUNNYLAB Brand Color (gold/amber)
GRADIENT1='\033[38;5;214m'  # gold
GRADIENT2='\033[38;5;214m'  # gold
GRADIENT3='\033[38;5;214m'  # gold
GRADIENT4='\033[38;5;214m'  # gold
GRADIENT5='\033[38;5;214m'  # gold
GRADIENT6='\033[38;5;214m'  # gold

# UI helpers
DIVIDER="${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
SMALL_DIVIDER="${CYAN}────────────────────────────────────────────${RESET}"

############################################################
# ARCH DETECTION
############################################################

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)    ARCH_ALT="amd64" ;;
    aarch64|arm64) ARCH_ALT="arm64" ;;
    *)
        echo -e "${RED}[ERROR] Unsupported architecture: $ARCH${RESET}"
        exit 1
        ;;
esac

############################################################
# ASCII ART LOGO – ROOTSUNNYLAB (clean, no CR7 confusion)
############################################################

show_logo() {
    clear
    echo -e "${GRADIENT1}"
    cat << "EOF"
██████╗  ██████╗  ██████╗ ████████╗███████╗██╗   ██╗███╗   ██╗███╗   ██╗██╗   ██╗
██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝██║   ██║████╗  ██║████╗  ██║╚██╗ ██╔╝
██████╔╝██║   ██║██║   ██║   ██║   ███████╗██║   ██║██╔██╗ ██║██╔██╗ ██║ ╚████╔╝ 
██╔══██╗██║   ██║██║   ██║   ██║   ╚════██║██║   ██║██║╚██╗██║██║╚██╗██║  ╚██╔╝  
██║  ██║╚██████╔╝╚██████╔╝   ██║   ███████║╚██████╔╝██║ ╚████║██║ ╚████║   ██║   
╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝   ╚═╝  
EOF
    echo -e "${GRADIENT1}                            ██╗      █████╗ ██████╗ ${RESET}"
    echo -e "${GRADIENT1}                            ██║     ██╔══██╗██╔══██╗${RESET}"
    echo -e "${GRADIENT1}                            ██║     ███████║██████╔╝${RESET}"
    echo -e "${GRADIENT1}                            ██║     ██╔══██║██╔══██╗${RESET}"
    echo -e "${GRADIENT1}                            ███████╗██║  ██║██████╔╝${RESET}"
    echo -e "${GRADIENT1}                            ╚══════╝╚═╝  ╚═╝╚═════╝ ${RESET}"
    echo -e "${YELLOW}        🌱 ROOTSUNNYLAB PROOT ENVIRONMENT 🔬${RESET}"
    echo ""
    echo -e "${DIVIDER}"
    echo -e "${GREEN}          Ubuntu 22.04 LTS Proot VM${RESET}"
    echo -e "${YELLOW}             Powered By ROOTSUNNYLAB${RESET}"
    echo -e "${DIVIDER}"
    echo ""
}

############################################################
# DEPENDENCY CHECK & INSTALL
############################################################

install_dependencies() {
    echo -e "${CYAN}[*] Checking system dependencies...${RESET}"
    local missing_pkgs=""
    for pkg in wget curl tar xz proot git pv; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            missing_pkgs+=" $pkg"
        fi
    done

    if [[ -n "$missing_pkgs" ]]; then
        echo -e "${YELLOW}[*] Installing missing packages:${missing_pkgs}${RESET}"
        if command -v apt >/dev/null 2>&1; then
            apt update -y && apt install -y $missing_pkgs
        elif command -v apk >/dev/null 2>&1; then
            apk add $missing_pkgs
        elif command -v yum >/dev/null 2>&1; then
            yum install -y $missing_pkgs
        else
            echo -e "${RED}[ERROR] Unsupported package manager. Please install manually.${RESET}"
            exit 1
        fi
    fi

    # Ensure proot binary exists globally if possible
    if ! command -v proot >/dev/null 2>&1; then
        echo -e "${YELLOW}[*] PRoot not in PATH – will use local copy.${RESET}"
    fi
}

############################################################
# DOWNLOAD WITH PROGRESS
############################################################

download_with_progress() {
    local url="$1"
    local output="$2"
    echo -e "${CYAN}[*] Downloading: $url${RESET}"

    if command -v pv >/dev/null 2>&1; then
        # Use wget to pipe through pv
        wget --tries="$MAX_RETRIES" --timeout="$TIMEOUT" --no-hsts -O - "$url" 2>/dev/null | pv -p -t -e -r -b > "$output"
    else
        wget --tries="$MAX_RETRIES" --timeout="$TIMEOUT" --show-progress --no-hsts -O "$output" "$url"
    fi

    if [[ ! -f "$output" ]]; then
        echo -e "${RED}[ERROR] Download failed.${RESET}"
        exit 1
    fi
}

############################################################
# INSTALL UBUNTU ROOTFS
############################################################

install_ubuntu() {
    local url="${ROOTFS_URL_UBUNTU//%%ARCH%%/$ARCH_ALT}"
    local tmpfile="/tmp/rootsunnylab_rootfs.tar.gz"

    echo -e "${CYAN}[*] Downloading Ubuntu 22.04 RootFS...${RESET}"
    download_with_progress "$url" "$tmpfile"

    echo -e "${GREEN}[*] Extracting filesystem...${RESET}"
    # Remove old partial install if any
    rm -rf "$ROOTSUNNYLAB_DIR"/*
    tar -xpf "$tmpfile" -C "$ROOTSUNNYLAB_DIR"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[ERROR] Extraction failed.${RESET}"
        rm -f "$tmpfile"
        exit 1
    fi
    rm -f "$tmpfile"
}

############################################################
# DOWNLOAD / UPDATE PROOT BINARY
############################################################

download_proot() {
    mkdir -p "$ROOTSUNNYLAB_DIR/usr/local/bin"
    echo -e "${CYAN}[*] Fetching PRoot binary...${RESET}"
    download_with_progress "$PROOT_URL" "$ROOTSUNNYLAB_DIR/usr/local/bin/proot"
    chmod +x "$ROOTSUNNYLAB_DIR/usr/local/bin/proot"
}

update_proot_binary() {
    echo -e "${YELLOW}[*] Updating PRoot binary...${RESET}"
    download_proot
    echo -e "${GREEN}[✔] PRoot updated.${RESET}"
}

############################################################
# CONFIGURE THE ROOTFS (first time setup)
############################################################

configure_system() {
    echo -e "${CYAN}[*] Configuring Ubuntu environment...${RESET}"

    # DNS
    mkdir -p "$ROOTSUNNYLAB_DIR/etc"
    cat > "$ROOTSUNNYLAB_DIR/etc/resolv.conf" <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

    # Setup script inside rootfs
    cat > "$ROOTSUNNYLAB_DIR/root/setup.sh" << 'INNERSCRIPT'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "==> Updating package lists..."
apt update -y

echo "==> Installing essential packages..."
apt install -y \
    sudo curl wget nano vim git htop neofetch net-tools \
    openssh-server ca-certificates software-properties-common \
    zip unzip screen tmux python3 python3-pip \
    bash-completion xz-utils pv jq sl lolcat cmatrix \
    zsh fonts-powerline

# Set root password
echo "root:${ROOT_PW:-root}" | chpasswd

# Create additional user if specified
if [[ -n "${EXTRA_USER:-}" ]]; then
    useradd -m -s /bin/bash "${EXTRA_USER}"
    echo "${EXTRA_USER}:${EXTRA_USER}" | chpasswd
    usermod -aG sudo "${EXTRA_USER}"
    echo "==> User ${EXTRA_USER} created."
fi

# SSH configuration
mkdir -p /var/run/sshd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ZSH & Oh-My-Zsh (for root)
if command -v zsh >/dev/null 2>&1; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    chsh -s $(which zsh) root
    # Powerlevel10k theme
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' /root/.zshrc
fi

# MOTD with ROOTSUNNYLAB branding
cat > /etc/motd << 'MOTD'
\033[1;36m  Welcome to ROOTSUNNYLAB Ubuntu 22.04! \033[0m
\033[1;33m    Fast · Stable · Beautiful \033[0m
MOTD

# Clean up
apt clean
echo "==> Setup complete!"
INNERSCRIPT

    # Pass variables into the rootfs environment
    export ROOT_PW="$ROOT_PASSWORD"
    export EXTRA_USER="$CREATE_USER"
    chmod +x "$ROOTSUNNYLAB_DIR/root/setup.sh"

    # Run the setup inside the new rootfs (proot)
    "$ROOTSUNNYLAB_DIR/usr/local/bin/proot" \
        --rootfs="$ROOTSUNNYLAB_DIR" \
        -0 -w /root \
        -b /dev -b /sys -b /proc -b /tmp \
        --kill-on-exit \
        /usr/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        ROOT_PW="$ROOT_PASSWORD" \
        EXTRA_USER="$CREATE_USER" \
        /bin/bash /root/setup.sh

    # Mark installation complete
    touch "$INSTALL_FLAG_FILE"
    echo -e "${GREEN}[✔] System configured successfully.${RESET}"
}

############################################################
# BACKUP & RESTORE
############################################################

backup_rootfs() {
    local backup_name="rootsunnylab_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo -e "${CYAN}[*] Creating backup: ${backup_name}${RESET}"
    cd "$ROOTSUNNYLAB_DIR"
    tar --exclude='./dev/*' --exclude='./proc/*' --exclude='./sys/*' --exclude='./tmp/*' \
        --exclude='./*.tar.gz' \
        --warning=no-file-changed \
        -czf "../$backup_name" . || true
    echo -e "${GREEN}[✔] Backup saved as ../$backup_name${RESET}"
}

restore_rootfs() {
    echo -e "${YELLOW}[!] Restoring will delete the current rootfs.${RESET}"
    read -p "Enter backup file path: " backup_path
    if [[ ! -f "$backup_path" ]]; then
        echo -e "${RED}[ERROR] File not found.${RESET}"
        return
    fi
    echo -e "${CYAN}[*] Restoring from $backup_path ...${RESET}"
    rm -rf "$ROOTSUNNYLAB_DIR"/*
    tar -xzf "$backup_path" -C "$ROOTSUNNYLAB_DIR"
    touch "$INSTALL_FLAG_FILE"
    echo -e "${GREEN}[✔] Restoration complete.${RESET}"
}

############################################################
# SYSTEM INFORMATION (host + container)
############################################################

show_system_info() {
    # Host info
    local RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
    local RAM_USED=$(free -m | awk '/Mem:/{print $3}')
    local RAM_FREE=$(free -m | awk '/Mem:/{print $4}')
    local CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d ':' -f2 | xargs)
    local CPU_CORES=$(nproc)
    local DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
    local DISK_USED=$(df -h / | awk 'NR==2{print $3}')
    local DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
    local IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
    local HOST_NAME=$(hostname)
    local KERNEL_VER=$(uname -r)
    local UPTIME_INFO=$(uptime -p)

    echo ""
    echo -e "${DIVIDER}"
    echo -e "${GREEN}${BOLD}               SYSTEM INFORMATION${RESET}"
    echo -e "${DIVIDER}"
    echo -e "${YELLOW}OS:${RESET} Ubuntu 22.04 LTS"
    echo -e "${YELLOW}Architecture:${RESET} $ARCH"
    echo -e "${YELLOW}Kernel:${RESET} $KERNEL_VER"
    echo -e "${YELLOW}Hostname:${RESET} $HOST_NAME"
    echo ""
    echo -e "${GREEN}CPU${RESET}"
    echo -e "  Model : ${WHITE}$CPU_MODEL${RESET}"
    echo -e "  Cores : ${WHITE}$CPU_CORES${RESET}"
    echo ""
    echo -e "${GREEN}RAM${RESET}"
    echo -e "  Total : ${WHITE}${RAM_TOTAL} MB${RESET}"
    echo -e "  Used  : ${WHITE}${RAM_USED} MB${RESET}"
    echo -e "  Free  : ${WHITE}${RAM_FREE} MB${RESET}"
    echo ""
    echo -e "${GREEN}Disk${RESET}"
    echo -e "  Total : ${WHITE}$DISK_TOTAL${RESET}"
    echo -e "  Used  : ${WHITE}$DISK_USED${RESET}"
    echo -e "  Free  : ${WHITE}$DISK_FREE${RESET}"
    echo ""
    echo -e "${GREEN}Network${RESET}"
    echo -e "  IP    : ${WHITE}${IP_ADDR:-Not Available}${RESET}"
    echo ""
    echo -e "${GREEN}Container${RESET}"
    echo -e "  Path  : ${WHITE}$ROOTSUNNYLAB_DIR${RESET}"
    echo -e "  Uptime: ${WHITE}$UPTIME_INFO${RESET}"
    echo -e "${DIVIDER}"
}

############################################################
# LAUNCH THE VM
############################################################

start_vm() {
    show_system_info
    echo -e "${MAGENTA}[*] Launching ROOTSUNNYLAB Ubuntu VM...${RESET}"
    echo ""
    exec "$ROOTSUNNYLAB_DIR/usr/local/bin/proot" \
        --rootfs="$ROOTSUNNYLAB_DIR" \
        -0 -w /root \
        -b /dev -b /sys -b /proc -b /tmp \
        -b /etc/resolv.conf \
        --kill-on-exit \
        /usr/bin/env -i \
        HOME=/root \
        TERM="$TERM" \
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        /bin/bash --login
}

############################################################
# INTERACTIVE MENU
############################################################

main_menu() {
    while true; do
        clear
        show_logo
        echo -e "${GREEN}${BOLD}           MAIN MENU${RESET}"
        echo -e "${SMALL_DIVIDER}"
        echo -e "${CYAN}1)${RESET} Start Ubuntu VM"
        echo -e "${CYAN}2)${RESET} Install / Reinstall RootFS"
        echo -e "${CYAN}3)${RESET} Update PRoot binary"
        echo -e "${CYAN}4)${RESET} Backup current RootFS(Broken)"
        echo -e "${CYAN}5)${RESET} Restore RootFS from backup(Broken)"
        echo -e "${CYAN}6)${RESET} Show system info"
        echo -e "${CYAN}7)${RESET} Exit"
        echo -e "${SMALL_DIVIDER}"
        read -p "Choose an option [1-7]: " choice

        case "$choice" in
            1)
                if [[ ! -f "$INSTALL_FLAG_FILE" ]]; then
                    echo -e "${RED}[!] RootFS not installed. Please install first.${RESET}"
                    sleep 2
                else
                    start_vm
                fi
                ;;
            2)
                read -p "This will erase current rootfs. Continue? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -rf "$ROOTSUNNYLAB_DIR"/* "$INSTALL_FLAG_FILE"
                    install_dependencies
                    install_ubuntu
                    download_proot
                    configure_system
                    echo -e "${GREEN}[✔] Installation complete!${RESET}"
                fi
                ;;
            3)
                update_proot_binary
                sleep 1
                ;;
            4)
                backup_rootfs
                sleep 2
                ;;
            5)
                restore_rootfs
                sleep 2
                ;;
            6)
                show_system_info
                echo ""
                read -p "Press Enter to return to menu..." dummy
                ;;
            7)
                echo -e "${YELLOW}Goodbye! 🌞${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${RESET}"
                sleep 1
                ;;
        esac
    done
}

############################################################
# INITIAL CHECKS & ENTRY POINT
############################################################

# Ensure we are in the right directory
cd "$ROOTSUNNYLAB_DIR"

# Safe argument handling (fixes unbound variable error)
QUICK_FLAG="${1:-}"   # default to empty if no argument

if [[ "$QUICK_FLAG" == "--quick-start" ]] && [[ -f "$INSTALL_FLAG_FILE" ]]; then
    show_logo
    start_vm
fi

# Otherwise, launch interactive menu
install_dependencies

if [[ ! -f "$INSTALL_FLAG_FILE" ]]; then
    echo -e "${YELLOW}[*] First run detected – starting guided setup...${RESET}"
    install_dependencies
    install_ubuntu
    download_proot
    configure_system
    echo -e "${GREEN}[✔] Setup finished. Welcome to ROOTSUNNYLAB!${RESET}"
    sleep 2
fi

main_menu
