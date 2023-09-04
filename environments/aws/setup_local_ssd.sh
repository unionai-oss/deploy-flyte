#!/bin/bash

set -exo pipefail

__bind_mount() {
  local source="$1"
  local destination="$2"

  # Move existing directory if it exists
  mkdir -p "$(dirname ${source})"
  [ ! -d ${destination} ] || mv ${destination} ${source}

  # Set up bind mount
  mkdir -p ${source} ${destination}
  echo "${source} ${destination} none defaults,bind 0 0" >> /etc/fstab
  mount ${destination}
}

__mountpath=/mnt/local-ssd-array
__raid_device=/dev/md/local-ssd-array
__devices=( $(find /dev/disk/by-id -name 'nvme-Amazon_EC2_NVMe_Instance_Storage_AWS*-ns-1' | xargs) )
__count=${#__devices[@]}

# no ssds present
if [[ ${__count} -eq 0 ]]; then
  exit 0

elif [[ ${__count} -eq 1 ]]; then
  # only 1 device so only format and mount
  mkfs.ext4 "${__devices[@]}"
  echo "${__devices[@]}" ${__mountpath} ext4 defaults,noatime 0 2 >> /etc/fstab

elif [[ ${__count} -gt 1 ]]; then
  # install mdadm
  yum -y install mdadm
  # config raid 0, format, and mount
  mdadm --create --verbose --level=0 ${__raid_device} --auto=yes --raid-devices="${__count}" "${__devices[@]}"
  mdadm --wait ${__raid_device} ||:
  mkfs.ext4 ${__raid_device}
  mdadm --detail --scan >> /etc/mdadm.conf
  dracut -H -f "/boot/initramfs-$(uname -r).img" "$(uname -r)"
  echo "${__raid_device} ${__mountpath} ext4 defaults,noatime 0 2" >> /etc/fstab
fi

mkdir -p ${__mountpath}
mount ${__mountpath}
__bind_mount "${__mountpath}/containerd/root" /var/lib/containerd
__bind_mount "${__mountpath}/containerd/state" /run/containerd
__bind_mount "${__mountpath}/docker" /var/lib/docker
__bind_mount "${__mountpath}/kubelet" /var/lib/kubelet
