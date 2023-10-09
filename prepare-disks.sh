#!/usr/bin/env bash

valid_layouts=("impermanence-tmpfs-btrfs")

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

echo "Layout is [$LAYOUT]"
echo "Disks are ${DISKS[*]}"
echo "Mirroring is [$MIRROR]"
echo "Encryption in [$ENCRYPT]"
echo "Boot Partition Size is [$BOOT_SIZE]"
echo "Swap Partition Size is [$SWAP_SIZE]"
