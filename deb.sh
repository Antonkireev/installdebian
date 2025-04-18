#!/bin/bash
set -e

CONFIG_FILE="hetzner-debian-installer.conf.bash"
SESSION_NAME="debian_install"

# Load config file if exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    echo "No configuration file found, proceeding interactively."
fi

# Auto-start inside screen session
#if [ -z "$STY" ]; then
#    if ! command -v screen &>/dev/null; then
#        echo "Installing screen..."
#        apt update && apt install screen -y
#    fi
#    echo "Launching installation inside screen session '$SESSION_NAME'..."
#    screen -dmS "$SESSION_NAME" bash "$0"
#    echo "Reconnect with: screen -r $SESSION_NAME"
#    exit 0
#fi

#screen -S "$STY" -X sessionname "$SESSION_NAME"

### CONFIGURE FUNCTIONS ###

configure_partitioning() {
  echo "Detected disks:"
  lsblk -o NAME,SIZE -dn | while read -r disk size; do
    if [[ $(lsblk -o TYPE -dn "/dev/$disk") == "disk" ]]; then
      echo "- /dev/$disk ($size)"
    fi
  done

  echo "[Configuring] Partitioning parameters"

  if [[ -z "$PART_DRIVE1" ]]; then
    read -rp 'Primary disk (e.g., nvme0n1): ' PART_DRIVE1
    PART_DRIVE1="${PART_DRIVE1:-nvme0n1}"
  fi

  if [[ -z "$PART_DRIVE2" ]]; then
    read -rp 'Secondary disk for RAID (optional): ' PART_DRIVE2
    PART_DRIVE2="${PART_DRIVE2:-nvme1n1}"
  fi

  if [[ -z "$PART_USE_RAID" ]]; then
    read -rp 'Use RAID? (yes/no): ' PART_USE_RAID
    PART_USE_RAID="${PART_USE_RAID:-yes}"
  fi

  if [[ -z "$PART_RAID_LEVEL" ]] && [[ "$PART_USE_RAID" == "yes" ]]; then
    read -rp 'RAID Level (e.g., 1): ' PART_RAID_LEVEL
    PART_RAID_LEVEL="${PART_RAID_LEVEL:-1}"
  fi

  if [[ -z "$PART_BOOT_SIZE" ]]; then
    read -rp 'Boot partition size (e.g., 512M): ' PART_BOOT_SIZE
    PART_BOOT_SIZE="${PART_BOOT_SIZE:-512M}"
  fi

  if [[ -z "$PART_SWAP_SIZE" ]]; then
    read -rp 'Swap size (e.g., 32G): ' PART_SWAP_SIZE
    PART_SWAP_SIZE="${PART_SWAP_SIZE:-32G}"
  fi

  if [[ -z "$PART_ROOT_FS" ]]; then
    read -rp 'Root filesystem type (e.g., ext4): ' PART_ROOT_FS
    PART_ROOT_FS="${PART_ROOT_FS:-ext4}"
  fi

  if [[ -z "$PART_BOOT_FS" ]]; then
    read -rp 'Boot filesystem type (e.g., ext3): ' PART_BOOT_FS
    PART_BOOT_FS="${PART_BOOT_FS:-ext3}"
  fi
}

configure_debian_install() {
   echo "[Configuring] Debian install parameters"

  if [[ -z "$DEBIAN_RELEASE" ]]; then
    read -rp "Choose Debian release (stable, testing, sid) [stable]: " DEBIAN_RELEASE
    DEBIAN_RELEASE="${DEBIAN_RELEASE:-stable}"
  fi

  if [[ -z "$DEBIAN_MIRROR" ]]; then
    read -rp "Enter Debian mirror [http://deb.debian.org/debian]: " DEBIAN_MIRROR
    DEBIAN_MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"
  fi

  if [[ -z "$INSTALL_TARGET" ]]; then
    read -rp "Enter install target [/mnt]: " INSTALL_TARGET
    INSTALL_TARGET="${INSTALL_TARGET:-/mnt}"
  fi

  if mount | grep -q "$INSTALL_TARGET"; then
    echo "Error: Unmount $INSTALL_TARGET"
    exit 1
  fi
}


#configure_network() {
#    echo "[Configuring] Network parameters"
#    : "${NETWORK_USE_DHCP:?$(read -rp 'Use DHCP? (yes/no): ' NETWORK_USE_DHCP)}"
#}

#configure_bootloader() {
#    echo "[Configuring] Bootloader parameters"
#    if [ -z "${GRUB_TARGET_DRIVES[*]}" ]; then
#        read -rp 'GRUB target drives (space-separated): ' -a GRUB_TARGET_DRIVES
#    fi
#}

#configure_initial_config() {
#    echo "[Configuring] Initial system settings"
#    : "${HOSTNAME:?$(read -rp 'Hostname: ' HOSTNAME)}"
#    : "${ROOT_PASSWORD:?$(read -rp 'Root password: ' ROOT_PASSWORD)}"
#}

#configure_cleanup() {
#    echo "[Configuring] Cleanup parameters (usually nothing to configure)"
#}

### RUN FUNCTIONS (Empty placeholders) ###
# run_partitioning() {
#   echo "[Running] Partitioning..."

#   if [[ "$PART_USE_RAID" == "yes" ]]; then
#     parted -s "/dev/$PART_DRIVE1" mklabel msdos
#     parted -s "/dev/$PART_DRIVE2" mklabel msdos
#     echo "Label disk ${PART_DRIVE1}: done"
#     sleep 2

#     echo yes | mdadm --create --verbose /dev/md0 --level="$PART_RAID_LEVEL" --raid-devices=2 "/dev/$PART_DRIVE1" "/dev/$PART_DRIVE2"
#     echo "RAID: done"
#     sleep 2

#     parted -s /dev/md0 mklabel msdos
#     echo "Label disk md0: done"
#     sleep 2

#     parted -s /dev/md0 mkpart primary ext3 1MiB "$PART_BOOT_SIZE"
#     echo "Partition boot: done"
#     sleep 2

#     parted -s /dev/md0 mkpart primary linux-swap "$PART_BOOT_SIZE" "$PART_SWAP_SIZE"
#     echo "Partition swap: done"
#     sleep 2

#     parted -s /dev/md0 mkpart primary "$PART_ROOT_FS" "$PART_SWAP_SIZE" 100%
#     echo "Partition root: done"
#     sleep 2

#     mkfs.ext3 "/dev/md0p1"
#     echo "Format boot partition: done"
#     sleep 2

#     mkswap "/dev/md0p2"
#     echo "mkswap: done"
#     sleep 2

#     swapon "/dev/md0p2"
#     echo "swapon: done"
#     sleep 2

#     mkfs.ext4 "/dev/md0p3"
#     echo "Format root partition: done"
#     sleep 2

#   else
#     parted -s "/dev/$PART_DRIVE1" mklabel msdos
#     echo "Label disk ${PART_DRIVE1}: done"
#     sleep 2

#     parted -s "/dev/$PART_DRIVE1" mkpart primary ext3 1MiB "$PART_BOOT_SIZE"
#     echo "Partition boot: done"
#     sleep 2

#     parted -s "/dev/$PART_DRIVE1" mkpart primary linux-swap "$PART_BOOT_SIZE" "$PART_SWAP_SIZE"
#     echo "Partition swap: done"
#     sleep 2

#     parted -s "/dev/$PART_DRIVE1" mkpart primary "$PART_ROOT_FS" "$PART_SWAP_SIZE" 100%
#     echo "Partition root: done"

#     mkfs.ext3 "/dev/${PART_DRIVE1}p1"
#     echo "Format boot partition: done"
#     sleep 2

#     mkswap "/dev/${PART_DRIVE1}p2"
#     echo "mkswap: done"
#     sleep 2

#     swapon "/dev/${PART_DRIVE1}p2"
#     echo "swapon: done"
#     sleep 2

#     mkfs.ext4 "/dev/${PART_DRIVE1}p3"
#     echo "Format root partition: done"
#     sleep 2
#   fi
# }


run_debian_install() {
  echo "[Running] Debian installation..."
  echo "Mounting target directory: $INSTALL_TARGET"
  mkdir -p "$INSTALL_TARGET/root"
  mkdir -p "$INSTALL_TARGET/boot"
  if [[ "$PART_USE_RAID" == "yes" ]]; then
    mount "/dev/md0p1" "$INSTALL_TARGET/boot"
    mount "/dev/md0p3" "$INSTALL_TARGET/root"
  else
    mount "/dev/${PART_DRIVE1}p1" "$INSTALL_TARGET/boot"
    mount "/dev/${PART_DRIVE1}p3" "$INSTALL_TARGET/root"
  fi
 echo "mount target directory: done"
  sleep 2
  # Запуск debootstrap
  echo "Starting debootstrap for $DEBIAN_RELEASE..."
  if debootstrap --arch=amd64 "$DEBIAN_RELEASE" "${INSTALL_TARGET}/root" "$DEBIAN_MIRROR"; then
    echo "Debian installed in $INSTALL_TARGET."
  else
    echo "Error: debootstrap failed"
    exit 1
  fi

}

#run_network() { echo "[Running] Network setup..."; }
#run_bootloader() { echo "[Running] Bootloader installation..."; }
#run_initial_config() { echo "[Running] Initial configuration..."; }
#run_cleanup() { echo "[Running] Cleanup and reboot..."; }

### Summary and Confirmation ###
summary_and_confirm() {
    echo ""
    echo "🚀 Configuration Summary:"
    echo "----------------------------------------"
    echo "Primary disk:          $PART_DRIVE1"
    echo "Secondary disk:        $PART_DRIVE2"
    echo "Use RAID:              $PART_USE_RAID (Level: $PART_RAID_LEVEL)"
    echo "Boot size/filesystem:  $PART_BOOT_SIZE / $PART_BOOT_FS"
    echo "Swap size:             $PART_SWAP_SIZE"
    echo "Root filesystem:       $PART_ROOT_FS"
    echo "Debian release/mirror: $DEBIAN_RELEASE / $DEBIAN_MIRROR"
    echo "Use DHCP:              $NETWORK_USE_DHCP"
    echo "GRUB targets:          ${GRUB_TARGET_DRIVES[*]}"
    echo "Hostname:              $HOSTNAME"
    echo "----------------------------------------"
    read -rp "Start installation with these settings? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Installation aborted by user."
        exit 1
    fi
}

### Entrypoints ###
configuring() {
#    configure_partitioning
    configure_debian_install
#    configure_network
#    configure_bootloader
#    configure_initial_config
#    configure_cleanup
}

running() {
#    run_partitioning
    run_debian_install
#    run_network
#    run_bootloader
#    run_initial_config
#    run_cleanup
}

main() {
    configuring
    summary_and_confirm
    running
}

main
