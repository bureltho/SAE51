# genMV.sh – Automatisation VirtualBox


## Résumé
Ce document décrit le script `genMV.sh` qui automatise la création, le listing, le démarrage, l’arrêt et la suppression de machines virtuelles VirtualBox via `VBoxManage`. Le script gère les métadonnées (date de création et utilisateur), vérifie les doublons, configure le boot PXE et s’arrête sur une pause pour vérification avant destruction.



## Points clés implémentés
Étape 1 – Création VM Debian1, RAM 4096 Mo, DD 64 GiB, NAT, PXE, pause, suppression  
Étape 2 – Vérification doublons  
Étape 3 – Configuration PXE/ISO  
Étape 4 – Gestion arguments L/N/S/D/A  
Étape 5 – Métadonnées et parsing

## Utilisation rapide

'chmod +x genMV.sh'
'./genMV.sh <commande> [nom_vm]'

| Commande | Description                         |
|----------|-------------------------------------|
| L        | Lister les VMs avec métadonnées     |
| N <nom>  | Créer une nouvelle VM `<nom>`       |
| S <nom>  | Supprimer la VM `<nom>`             |
| D <nom>  | Démarrer la VM `<nom>`              |
| A <nom>  | Arrêter la VM `<nom>`               |


## Problèmes rencontrés

**Conflit de noms de VM**  
   Lors de créations répétées, `createvm` échouait si une VM du même nom existait.  
   **Solution** : Vérification et suppression automatique en début de création.

**Permissions d’exécution manquantes**  
   Au lancement du script, le message Permission denied apparaissait. Le script n’était pas marqué comme exécutable.  
   **Solution** : Exécuter chmod +x genMV.sh pour ajouter le bit d’exécution et permettre son lancement direct.


