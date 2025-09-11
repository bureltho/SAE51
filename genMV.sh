#!/bin/bash

# Variables configurables
RAM=4096
DISK=64
OS_TYPE="Debian_64"
ISO_PATH="$HOME/iso/debian-netinst.iso"
VM_DIR="$HOME/VirtualBox VMs"

# Aide
if [ $# -lt 1 ]; then
  echo "Usage: $0 {L|N|S|D|A} [nom_vm]"
  exit 1
fi

ACTION="$1"
NAME="$2"

# Vérifie existence
exists() {
  VBoxManage showvminfo "$1" &>/dev/null
}

# Créer VM
create() {
  if exists "$1"; then
    delete "$1"
  fi
  VBoxManage createvm --name "$1" --ostype "$OS_TYPE" --register
  VBoxManage modifyvm "$1" --memory $RAM --nic1 nat --boot1 net
  VBoxManage storagectl "$1" --name SATA --add sata --controller IntelAhci
  VBoxManage createmedium disk --filename "$VM_DIR/$1/$1.vdi" --size $((DISK*1024)) --format VDI
  VBoxManage storageattach "$1" --storagectl SATA --port 0 --device 0 --type hdd --medium "$VM_DIR/$1/$1.vdi"
  [ -f "$ISO_PATH" ] && VBoxManage storageattach "$1" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$ISO_PATH"
  # Métadonnées
  DATE=$(date "+%Y-%m-%d_%H:%M:%S")
  VBoxManage setextradata "$1" creation.date "$DATE"
  VBoxManage setextradata "$1" creation.user "$USER"
  echo "VM $1 créée. Vérifiez dans la GUI puis appuyez sur Entrée."
  read
  delete "$1"
}

# Supprimer VM
delete() {
  if exists "$1"; then
    VBoxManage controlvm "$1" poweroff &>/dev/null
    sleep 1
    VBoxManage unregistervm "$1" --delete
    echo "VM $1 supprimée."
  else
    echo "VM $1 introuvable."
  fi
}

# Démarrer VM
start() {
  if exists "$1"; then
    VBoxManage startvm "$1" --type headless
  else
    echo "VM $1 introuvable."
  fi
}

# Arrêter VM
stop() {
  if exists "$1"; then
    VBoxManage controlvm "$1" acpipowerbutton
  else
    echo "VM $1 introuvable."
  fi
}

# Lister VMs
list() {
  VBoxManage list vms > /tmp/vms.txt
  while read -r line; do
    vm=$(echo "$line" | cut -d'"' -f2)
    echo "- $vm"
    date=$(VBoxManage getextradata "$vm" creation.date 2>/dev/null | cut -d' ' -f2-)
    user=$(VBoxManage getextradata "$vm" creation.user 2>/dev/null | cut -d' ' -f2-)
    [ -n "$date" ] && echo "  Date: $date"
    [ -n "$user" ] && echo "  User: $user"
  done < /tmp/vms.txt
  rm /tmp/vms.txt
}

case "$ACTION" in
  L) list ;;
  N) [ -n "$NAME" ] && create "$NAME" || echo "Nom requis" ;;
  S) [ -n "$NAME" ] && delete "$NAME" || echo "Nom requis" ;;
  D) [ -n "$NAME" ] && start "$NAME" || echo "Nom requis" ;;
  A) [ -n "$NAME" ] && stop "$NAME" || echo "Nom requis" ;;
  *) echo "Commande invalide"; exit 1 ;;
esac
