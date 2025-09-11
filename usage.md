# genMV.sh – Automatisation VirtualBox

**Auteurs** : [Nom Étudiant 1], [Nom Étudiant 2]  
**Date** : 11 septembre 2025  
**Version** : 1.0

## Résumé
Ce document décrit le script `genMV.sh` qui automatise la création, le listing, le démarrage, l’arrêt et la suppression de machines virtuelles VirtualBox via `VBoxManage`. Le script gère les métadonnées (date de création et utilisateur), vérifie les doublons, configure le boot PXE et s’arrête sur une pause pour vérification avant destruction.

## Installation et prérequis
…  

## Utilisation
…  

## Configuration (en tête du script)
…  

## Points clés implémentés
1. Étape 1 – Création VM Debian1, RAM 4096 Mo, DD 64 GiB, NAT, PXE, pause, suppression  
2. Étape 2 – Vérification doublons  
3. Étape 3 – Configuration PXE/ISO  
4. Étape 4 – Gestion arguments L/N/S/D/A  
5. Étape 5 – Métadonnées et parsing

## Limites et améliorations possibles
- Configuration manuelle TFTP  
- Automatisation preseed  
- Autologon  
- Réseau avancé  
- Interface web  

*Ce rapport respecte la consigne : titre, auteurs, date et résumé de 4–5 lignes.*
