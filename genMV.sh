#!/bin/bash

# Variables configurables (étape 4)
RAM=4096
DISK_SIZE=64
OS_TYPE="Debian_64"
ISO_PATH="$HOME/iso/debian-netinst.iso"
VM_DIR="$HOME/VirtualBox VMs"

# Fonction d'aide
function usage() {
    echo "Usage: $0 {L|N|S|D|A} [nom_vm]"
    echo "  L          : Lister les machines"
    echo "  N <nom>    : Créer une nouvelle machine"
    echo "  S <nom>    : Supprimer une machine"
    echo "  D <nom>    : Démarrer une machine"
    echo "  A <nom>    : Arrêter une machine"
    exit 1
}

# Vérifier si une VM existe
function vm_exists() {
    VBoxManage showvminfo "$1" &>/dev/null
    return $?
}

# Créer une nouvelle VM (étapes 1, 2, 3)
function create_vm() {
    local VM_NAME="$1"
    
    echo "=== Création de la VM $VM_NAME ==="
    
    # Étape 2 : Vérifier qu'une machine de même nom n'existe pas déjà
    if vm_exists "$VM_NAME"; then
        echo "La VM $VM_NAME existe déjà, suppression..."
        delete_vm "$VM_NAME"
    fi
    
    # Étape 1 : Créer une machine Debian1 de type Linux/Debian 64 bits
    VBoxManage createvm --name "$VM_NAME" --ostype "$OS_TYPE" --register
    if [ $? -ne 0 ]; then
        echo "Erreur : impossible de créer la VM"
        exit 1
    fi
    
    # Configurer 4096 MB de RAM, carte réseau NAT, boot PXE
    VBoxManage modifyvm "$VM_NAME" --memory $RAM --nic1 nat --boot1 net
    if [ $? -ne 0 ]; then
        echo "Erreur : impossible de configurer la VM"
        exit 1
    fi
    
    # Créer le contrôleur SATA
    VBoxManage storagectl "$VM_NAME" --name "SATA" --add sata --controller IntelAhci
    
    # Créer un DD de 64 GiB
    VBoxManage createmedium disk --filename "$VM_DIR/$VM_NAME/$VM_NAME.vdi" --size $((DISK_SIZE * 1024)) --format VDI
    if [ $? -ne 0 ]; then
        echo "Erreur : impossible de créer le disque"
        exit 1
    fi
    
    # Attacher le disque
    VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VM_DIR/$VM_NAME/$VM_NAME.vdi"
    
    # Étape 3 : Attacher l'ISO Debian netinst si disponible
    if [ -f "$ISO_PATH" ]; then
        VBoxManage storageattach "$VM_NAME" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium "$ISO_PATH"
    fi
    
    # Étape 5 : Ajouter les métadonnées
    local DATE=$(date "+%Y-%m-%d_%H:%M:%S")
    VBoxManage setextradata "$VM_NAME" "creation.date" "$DATE"
    VBoxManage setextradata "$VM_NAME" "creation.user" "$USER"
    
    echo "VM $VM_NAME créée avec succès"
    
    # Étape 1 : Pause puis destruction
    echo "PAUSE : vérifiez avec la GUI de VB que la machine existe"
    read -p "Appuyez sur Entrée pour continuer..."
    
    # Détruire la machine
    delete_vm "$VM_NAME"
}

# Supprimer une machine
function delete_vm() {
    local VM_NAME="$1"
    if vm_exists "$VM_NAME"; then
        VBoxManage controlvm "$VM_NAME" poweroff &>/dev/null
        sleep 2
        VBoxManage unregistervm "$VM_NAME" --delete
        echo "VM $VM_NAME supprimée"
    else
        echo "La VM $VM_NAME n'existe pas"
    fi
}

# Démarrer une machine
function start_vm() {
    local VM_NAME="$1"
    if ! vm_exists "$VM_NAME"; then
        echo "Erreur : la VM $VM_NAME n'existe pas"
        exit 1
    fi
    VBoxManage startvm "$VM_NAME" --type headless
    echo "VM $VM_NAME démarrée"
}

# Arrêter une machine
function stop_vm() {
    local VM_NAME="$1"
    if ! vm_exists "$VM_NAME"; then
        echo "Erreur : la VM $VM_NAME n'existe pas"
        exit 1
    fi
    VBoxManage controlvm "$VM_NAME" acpipowerbutton
    echo "Signal d'arrêt envoyé à la VM $VM_NAME"
}

# Lister les machines avec métadonnées (étape 5)
function list_vms() {
    echo "=== Liste des machines ==="
    
    # Rediriger la sortie vers un fichier texte (comme indiqué dans le cahier des charges)
    VBoxManage list vms > /tmp/liste.txt
    
    if [ ! -s /tmp/liste.txt ]; then
        echo "Aucune machine enregistrée"
        rm -f /tmp/liste.txt
        return
    fi
    
    # Parser ligne par ligne avec une boucle FOR
    while IFS= read -r line; do
        # Séparer les champs par l'espace, utiliser le 1er champ (nom de la machine)
        VM_NAME=$(echo "$line" | cut -d'"' -f2)
        
        # Utiliser getextradata pour afficher les métadonnées
        DATE_META=$(VBoxManage getextradata "$VM_NAME" "creation.date" | awk '{print $2}')
        USER_META=$(VBoxManage getextradata "$VM_NAME" "creation.user" | awk '{print $2}')
        
        echo "- $VM_NAME"
        if [ "$DATE_META" != "No" ]; then
            echo "  Créé le: $DATE_META"
        fi
        if [ "$USER_META" != "No" ]; then
            echo "  Par: $USER_META"
        fi
        
    done < /tmp/liste.txt
    
    rm -f /tmp/liste.txt
}

# Programme principal

# Vérifier les arguments
if [ $# -lt 1 ]; then
    usage
fi

ACTION="$1"
VM_NAME="$2"

# Étape 4 : Gestion d'arguments (L/N/S/D/A)
case "$ACTION" in
    L)
        list_vms
        ;;
    N)
        if [ -z "$VM_NAME" ]; then
            echo "Erreur : nom de la VM requis"
            exit 1
        fi
        create_vm "$VM_NAME"
        ;;
    S)
        if [ -z "$VM_NAME" ]; then
            echo "Erreur : nom de la VM requis"
            exit 1
        fi
        delete_vm "$VM_NAME"
        ;;
    D)
        if [ -z "$VM_NAME" ]; then
            echo "Erreur : nom de la VM requis"
            exit 1
        fi
        start_vm "$VM_NAME"
        ;;
    A)
        if [ -z "$VM_NAME" ]; then
            echo "Erreur : nom de la VM requis"
            exit 1
        fi
        stop_vm "$VM_NAME"
        ;;
    *)
        echo "Erreur : commande inconnue"
        usage
        ;;
esac

exit 0
