#!/bin/bash
# Variables
RAM=4096
DISK=64
ISO="$HOME/iso/debian-netinst.iso"
# Aide
if [ $# -lt 1 ]; then
  echo "Usage: $0 {L|N|S|D|A} [VM_NAME]" >&2
  exit 1
fi
CMD="$1"
VM="$2"
# Vérifier existence
exists() {
  VBoxManage showvminfo "$1" &>/dev/null
}
# Créer VM
create() {
  [ -z "$VM" ] && { echo "Erreur: nom requis" >&2; exit 1; }
  if exists "$VM"; then
    echo "Erreur: la VM '$VM' existe déjà." >&2
    exit 1
  fi
  VBoxManage createvm --name "$VM" --ostype "Debian_64" --register \
    || { echo "Erreur createvm" >&2; exit 1; }
  VBoxManage modifyvm "$VM" --memory $RAM --nic1 nat --boot1 net \
    || { echo "Erreur modifyvm" >&2; exit 1; }
  VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci \
    || { echo "Erreur storagectl" >&2; exit 1; }
  VBoxManage createmedium disk --filename "$VM.vdi" --size $((DISK*1024)) \
    || { echo "Erreur createmedium" >&2; exit 1; }
  VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type hdd --medium "$VM.vdi" \
    || { echo "Erreur storageattach disque" >&2; exit 1; }
  [ -f "$ISO" ] && VBoxManage storageattach "$VM" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$ISO" \
    || echo "ISO non trouvée"
  echo "VM $VM créée."
}
# Supprimer VM
delete() {
  [ -z "$VM" ] && { echo "Erreur: nom requis" >&2; exit 1; }
  exists "$VM" || { echo "Erreur: VM introuvable" >&2; exit 1; }
  VBoxManage unregistervm "$VM" --delete \
    || { echo "Erreur unregistervm" >&2; exit 1; }
  echo "VM $VM supprimée."
}
# Démarrer VM
start() {
  [ -z "$VM" ] && { echo "Erreur: nom requis" >&2; exit 1; }
  exists "$VM" || { echo "Erreur: VM introuvable" >&2; exit 1; }
  VBoxManage startvm "$VM" --type headless \
    || { echo "Erreur startvm" >&2; exit 1; }
  echo "VM $VM démarrée."
}
# Arrêter VM
stop() {
  [ -z "$VM" ] && { echo "Erreur: nom requis" >&2; exit 1; }
  exists "$VM" || { echo "Erreur: VM introuvable" >&2; exit 1; }
  VBoxManage controlvm "$VM" acpipowerbutton \
    || { echo "Erreur arrêt ACPI" >&2; exit 1; }
  echo "Signal arrêt envoyé."
}
# Lister VMs
list() {
  VBoxManage list vms | cut -d'"' -f2 \
    || { echo "Erreur list vms" >&2; exit 1; }
}
case "$CMD" in
  N) create ;;
  S) delete ;;
  D) start ;;
  A) stop ;;
  L) list ;;
  *) echo "Commande invalide" >&2; exit 1 ;;
esac
