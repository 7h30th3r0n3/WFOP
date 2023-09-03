#!/bin/bash
# WFOP by 7h30th3r0n3 
# Designed to quickly identify open port and command to close it

if [ "$EUID" -ne 0 ]
  then echo "Ce programme doit être lancé avec les droits root. Veuillez relancer avec sudo."
  exit
fi
clear
echo " "
echo "                         WFOP : Who the Fuck Opened a Port ! "
echo " "

# Utilisation de netstat pour lister tous les ports ouverts
ports=$(netstat -tuln | grep LISTEN | awk '{print $4}' | awk -F: '{print $NF}' | sort -n | uniq)

if [ -z "$ports" ]; then
    echo "                                Aucun port ouvert !"
    exit 0
fi

echo "Liste des programmes qui ont ouvert des ports :"
echo "----------------------------------------------------------------------------------------"

# Initialisation des variables pour la commande de fermeture des ports
kill_cmd=""

# Boucle pour chaque port ouvert
while read -r port; do
    # Utilisation de lsof pour trouver le PID du programme qui ouvre le port
    pid=$(lsof -i:$port | awk '{print $2}' | tail -1)
    if [ "$pid" != "" ]; then
        # Utilisation de ps pour trouver le nom du programme à partir de son PID
        cmd=$(ps -p $pid -o comm=)
        # Utilisation de lsof pour vérifier l'état du port
        etat=$(lsof -i:$port | grep -v PID | awk '{print $NF}' | sort | uniq)
        # Utilisation de lsof pour trouver le programme ou le service du port
        connections=$(lsof -i:$port | grep -v PID | awk '{print $1}' | sort | uniq)
        # Utilisation de lsof pour trouver les utilisateurs qui ont ouvert le port
        users=$(lsof -i:$port | grep -v PID | awk '{print $3}' | sort | uniq)
        # Vérification si le programme qui ouvre le port est un service
        service=$(systemctl list-units | grep $cmd | awk '{print $1}')
        if [ "$service" != "" ]; then
            echo "Le port $port est ouvert par le service $service en mode $etat"
            echo "Programme : $connections"
            echo "Utilisateur : $users"
            echo "Pour fermer le port utiliser la commande : sudo systemctl stop $service"
            kill_cmd+="sudo systemctl stop $service; "
        else
            echo "Le port $port est ouvert par le programme $cmd (PID $pid) en mode $etat"
            echo "Programme : $connections"
            echo "Utilisateur : $users"
            echo "Pour fermer le port utiliser la commande : sudo kill -9 $pid"
            kill_cmd+="sudo kill -9 $pid; "
        fi
        echo "----------------------------------------------------------------------------------------"
    fi
done <<< "$ports"

# Affichage de la commande de fermeture des ports
echo "Pour fermer tous les ports, utilisez la commande :"
echo "$kill_cmd"

exit 0
