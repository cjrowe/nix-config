#!/usr/bin/env bash

valid_layouts=("impermanence-tmpfs-btrfs")
SUBVOL_PERSIST=persist
SUBVOL_NIX=nix
SUBVOL_NIXOS_CONFIG=nixos-config
SUBVOL_LOGS=logs

LAYOUT="impermanence-tmpfs-btrfs"
DISKS=()
MIRROR=false
BOOT_SIZE="1G"
SWAP_SIZE="8G"
ENCRYPT=false

usage() {
  echo "Usage: $0 [ -d DISK_ID ] [ -l LAYOUT ] [ -m ] [-e] [-b BOOT_PARTITION_SIZE ] [ -s SWAP_PARTITION_SIZE ]" 1>&2
}

exit_abnormal() {
  usage
  exit 1
}

layout_string_is_valid() {
  valid_layout_string=false
  for i in "${valid_layouts[@]}"
  do
    [ "$i" == "$1" ] && valid_layout_string=true && break
  done

  [ "$valid_layout_string" == false ] && echo "[$1] is not a valid partition layout" && exit_abnormal
}

number_of_disks_is_correct() {
  correct_number_of_disks=false
  case "$2" in
    true)
      [ ${#$1[@]} == 2 ] && correct_number_of_disks=true
      ;;
    false)
      [ ${#$1[@]} == 1 ] && correct_number_of_disks=true
      ;;
  esac

  [ "$correct_number_of_disks" == false ] && echo "Incorrect number of disks specified" && exit_abnormal
}

partition_size_is_valid() {
  valid_partition_size=false
  [[ "$1" =~ ^[0-9]+[MG]{1}$ ]] && valid_partition_size=true

  [ "$valid_partition_size" == false ] && echo "Invalid partition size: [$1]" && exit_abnormal
}

partition_disks() {
  for disk in "${1[@]}"
  do
    echo "Partitioning Disk [$disk]..."
    sgdisk -n 0:0:+$BOOT_SIZE -t 0:ea00 -c 0:boot "$disk"
    sgdisk -n 0:0:+$SWAP_SIZE -t 0:8200 -c 0:swap "$disk"
    sgdisk -n 0:0:0 -t 0:8300 -c 0:root "$disk"
    echo "Partitioning Complete..."
    sgdisk -p "$disk"
  done
}

create_efi_filesystem() {
  for disk in "${1[@]}"
  do
    echo "Creating EFI filesystem on [$disk]..."
    mkfs.vfat "$disk-part1"
  done
}

enable_swap() {
  for disk in "${1[@]}"
  do
    echo "Enabling Swap on [$disk]..."
    mkswap "$disk-part2"
    swapon "$disk-part2"
  done
}

create_persistent_filesystem() {
  echo "Creating persistent filesystem(s)..."
  case "$2" in
    impermanence-tmpfs-btrfs)
      if [[ "$4" == true ]]
      then
        create_mirrored_btrfs_filesystem "${1[*]}" "$3"
      else
        create_single_btrfs_filesystem "${1[0]}" "$3"
      fi

      btrfs_fs="${1[0]}-part3"
      [ "$3" == true ] && btrfs_fs="/dev/mapper/crypt-1"
      create_btrfs_impermanence_subvolumes "$btrfs_fs"
      echo "Mounting / as tmpfs..." && mount -t tmpfs none /mnt
      echo "Creating base directories..." && mkdir -p /mnt/{boot,home,nix,persist,etc/nixos,var/log}
      echo "Mounting /boot..." && mount "${1[0]}-part1" /mnt/boot
      [ "$4" == true ] && echo "Mounting /boot-fallback as boot mirror..." && mkdir -p /mnt/boot-fallback && mount "${1[1]}-part1" /mnt/boot-fallback
      echo "Mounting /home as tmpfs..." && mount -t tmpfs none /mnt/home
      echo "Mounting /nix..." && mount -o "subvol=$SUBVOL_NIX,compress=zstd,noatime" "$btrfs_fs" /mnt/nix
      echo "Mounting /persist..." && mount -o "subvol=$SUBVOL_PERSIST,compress=zstd" "$btrfs_fs" /mnt/persist
      echo "Mounting /etc/nixos..." && mount -o "subvol=$SUBVOL_NIXOS_CONFIG,compress=zstd" "$btrfs_fs" /mnt/etc/nixos
      echo "Mounting /var/log..." && mount -o "subvol=$SUBVOL_LOGS,compress=zstd" "$btrfs_fs" /mnt/var/log
      ;;
  esac
}

create_mirrored_btrfs_filesystem() {
  echo "Creating mirrored BTRFS filesystem..."
  INDEX=1
  FS_LOCATIONS=()
  for disk in "${1[@]}"
  do
    fs_location="$disk-part3"
    [ "$2" == true ] && luks_encrypt_partition "$disk-part3" "$INDEX" && fs_location="/dev/mapper/crypt-$INDEX"
    ((++INDEX))
    FS_LOCATIONS+=(fs_location)
  done

  mkfs.btrfs -m raid1 -d raid1 "${FS_LOCATIONS[*]}"
}

create_single_btrfs_filesystem() {
  echo "Creating single disk BTRFS filesystem..."
  fs_location="$1-part3"
  [ "$2" == true ] && luks_encrypt_partition "$1-part3" "1" && fs_location="/dev/mapper/crypt-1"
  mkfs.btrfs "$fs_location"
}

luks_encrypt_partition() {
  echo "LUKS encrypting partition [$1]..."
  echo "Enter passphrase when prompted..."
  cryptsetup --verify-passphrase -v luksFormat "$1"
  cryptsetup open "$1" "crypt-$2"
}

create_btrfs_impermanence_subvolumes() {
  echo "Creating BTRFS Subvolumes..."
  mount -t btrfs "$1" /mnt

  btrfs subvolume create "/mnt/$SUBVOL_SUBVOL_LOGS"
  btrfs subvolume create "/mnt/$SUBVOL_NIX"
  btrfs subvolume create "/mnt/$SUBVOL_NIXOS_CONFIG"
  btrfs subvolume create "/mnt/$SUBVOL_PERSIST"

  echo "BTRFS Subvolumes Created..."
  btrfs subvolume list /mnt

  umount /mnt
}

echo "NixOS Disk Preparation Script"
echo "============================="

while getopts "b:d:el:ms:" options; do
  case "${options}" in
    b)
      BOOT_SIZE=${OPTARG}
      ;;
    d)
      DISKS+=("$OPTARG")
      ;;
    e)
      ENCRYPT=true
      ;;
    l)
      LAYOUT=${OPTARG}
      ;;
    m)
      MIRROR=true
      ;;
    s)
      SWAP_SIZE=${OPTARG}
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument"
      exit_abnormal
      ;;
    *)
      exit_abnormal
      ;;
  esac
done

layout_string_is_valid "$LAYOUT"
number_of_disks_is_correct "${DISKS[*]}" $MIRROR
partition_size_is_valid "$BOOT_SIZE"
partition_size_is_valid "$SWAP_SIZE"

echo "Disk(s) will be configured as follows:"
echo "Layout is [$LAYOUT]"
echo "Disks are ${DISKS[*]}"
echo "Mirroring is [$MIRROR]"
echo "Encryption in [$ENCRYPT]"
echo "Boot Partition Size is [$BOOT_SIZE]"
echo "Swap Partition Size is [$SWAP_SIZE]"

partition_disks "${DISKS[*]}"
create_efi_filesystem "${DISKS[*]}"
enable_swap "${DISKS[*]}"
create_persistent_filesystem "${DISKS[*]}" "$LAYOUT" "$ENCRYPT" "$MIRROR"

echo "Disk(s) Prepared..." && lsblk -f
echo "Generating NixOS base configuration..." && nixos-generate-config --root /mnt
