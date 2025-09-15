#!/bin/bash
RAM=4096
DISK=64
ISO="/home/user/SAE52/ISO/debian-13.1.0-amd64-netinst.iso"

CMD="$1"
VM="$2"
# Vérifier existence
exists() {
  VBoxManage showvminfo "$1" &>/dev/null
  return $?
}
# Créer VM
create() {
  [ -z "$VM" ] && { echo "Erreur: nom requis" >&2; exit 1; }
  exists "$VM" && { echo "Erreur: la VM '$VM' existe déjà." >&2; exit 1; }
  [ ! -f "$ISO" ] && { echo "Erreur: ISO non trouvée à $ISO" >&2; exit 1; }

  VBoxManage createvm --name "$VM" --ostype "Debian_64" --register || { echo "Erreur createvm" >&2; exit 1; }
  VBoxManage modifyvm "$VM" --memory "$RAM" --nic1 nat --boot1 dvd --boot2 disk --boot3 none --vram 128 --graphicscontroller vmsvga || { echo "Erreur modifyvm" >&2; exit 1; }
  VBoxManage storagectl "$VM" --name SATA --add sata --controller IntelAhci || { echo "Erreur storagectl" >&2; exit 1; }
  VBoxManage createmedium disk --filename "$VM.vdi" --size $((DISK*1024)) || { echo "Erreur createmedium" >&2; exit 1; }
  VBoxManage storageattach "$VM" --storagectl SATA --port 0 --device 0 --type hdd --medium "$VM.vdi" || { echo "Erreur storageattach disque" >&2; exit 1; }
  VBoxManage storageattach "$VM" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$ISO" || { echo "Erreur storageattach ISO" >&2; exit 1; }

  CREATION_DATE=$(date +%Y-%m-%d_%H:%M:%S)
  CREATOR_USER="${USER:-$(whoami)}"
  VBoxManage setextradata "$VM" "CreationDate" "$CREATION_DATE" && echo "Métadonnée CreationDate ajoutée : $CREATION_DATE" || { echo "Erreur ajout métadonnée CreationDate" >&2; exit 1; }
  VBoxManage setextradata "$VM" "CreatorUser" "$CREATOR_USER" && echo "Métadonnée CreatorUser ajoutée : $CREATOR_USER" || { echo "Erreur ajout métadonnée CreatorUser" >&2; exit 1; }

  echo "VM $VM créée avec succès."
}
# Supprimer VM
delete() {
  [ -z "$VM" ] && { echo "Erreur: nom requis" >&2; exit 1; }
  exists "$VM" || { echo "Erreur: VM introuvable" >&2; exit 1; }
  if VBoxManage showvminfo "$VM" --machinereadable | grep -q '^VMState="running"$'; then
    echo "VM $VM en cours d'exécution → arrêt forcé..."
    VBoxManage controlvm "$VM" poweroff || { echo "Erreur poweroff" >&2; exit 1; }
    sleep 2
  fi
  VBoxManage unregistervm "$VM" --delete || { echo "Erreur unregistervm" >&2; exit 1; }
  echo "VM $VM supprimée avec succès."
}
# Démarrer VM
start() {
  [ -z "$VM" ] && { echo "Erreur: nom requis" >&2; exit 1; }
  exists "$VM" || { echo "Erreur: VM introuvable" >&2; exit 1; }
  VBoxManage startvm "$VM" --type gui || { echo "Erreur startvm" >&2; exit 1; }
  echo "VM $VM démarrée avec succès."
}
# Arrêter VM
stop() {
  [ -z "$VM" ] && { echo "Erreur: nom requis" >&2; exit 1; }
  exists "$VM" || { echo "Erreur: VM introuvable" >&2; exit 1; }
  echo "Envoi du signal d'arrêt ACPI à la VM $VM..."
  VBoxManage controlvm "$VM" acpipowerbutton
  for i in {1..10}; do
    if ! VBoxManage showvminfo "$VM" --machinereadable | grep -q '^VMState="running"$'; then
      echo "VM $VM arrêtée avec succès."
      return 0
    fi
    sleep 1
  done
  echo "arrêt en cours..."
  VBoxManage controlvm "$VM" poweroff || { echo "Erreur arrêt forcé" >&2; exit 1; }
  sleep 2
  echo "VM $VM arrêtée avec succès (arrêt forcé appliqué)."
}
# Lister VMs
list() {
  VBoxManage list vms > /tmp/vms_list.txt 2>/dev/null || { echo "Erreur list vms" >&2; exit 1; }
  echo "Liste des VMs avec métadonnées :"
  echo "Nom VM                  | Date Création       | Utilisateur Créateur"
  while read -r line; do
    if [[ $line =~ \"([^\"]+)\" ]]; then
      VM_NAME="${BASH_REMATCH[1]}"
      CREATION_DATE=$(VBoxManage getextradata "$VM_NAME" "CreationDate" 2>/dev/null || echo "N/A")
      CREATOR_USER=$(VBoxManage getextradata "$VM_NAME" "CreatorUser" 2>/dev/null || echo "N/A")
      printf "%-24s | %-19s | %-20s\n" "$VM_NAME" "$CREATION_DATE" "$CREATOR_USER"
    fi
  done < /tmp/vms_list.txt
  rm -f /tmp/vms_list.txt
}
case "$CMD" in
  N) create ;;
  S) delete ;;
  D) start ;;
  A) stop ;;
  L) list ;;
  *) echo "Commande invalide" >&2; exit 1 ;;
esac
