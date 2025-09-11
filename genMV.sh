RAM=4096
DD_SIZE=64

case "$1" in
    "L")

        VBoxManage list vms
        ;;
    "N")
        if [ -z "$2" ]; then
            echo "Erreur : Nom de la machine manquant pour N"
            exit 1
        fi

VBoxManage createvm --name "Debian1" --ostype "$2" --register
VBoxManage modifyvm "Debian1" --memory 4096 --vram 16 --nic1 nat --boot1 net
VBoxManage createmedium disk --filename "Debian1.vdi" --size 64
VBoxManage storagectl "Debian1" --name "SATA" --add sata
VBoxManage storageattach "Debian1" --storagectl "SATA" --port 0 --device 0 --type hdd --medium "Debian1.vdi"

  
   "S")
        if VBoxManage list vms | grep -q '"Debian1"'; then
             echo "Une MV Debian1 existe déjà. Suppression en cours..."
             VBoxManage unregistervm "Debian1" --delete
        fi

echo "VM Debian1 créée..."
read

VBoxManage unregistervm "Debian1" --delete
echo "VM supprimée."
