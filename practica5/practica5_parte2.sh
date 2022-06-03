#!/bin/bash
#755848, Cánovas, Guillermo, T, 2, B
#759934, Huszak, Ioan Paul, T, 2, B

if [ "$#" -ne 1 ]
then
    echo "Numero de parametros incorrecto"
    exit 85
fi
ip=$(echo "$1" | cut -d '@' -f2)

if ! ping -c1 "$ip"  > /dev/null #Comprobamos la accesibilidad de la máquina
then
    echo "No se puede acceder a la direccion: $ip"
    exit 1
fi

ssh "$1" "sudo sfdisk -s"
ssh "$1" "sudo sfdisk -l"
ssh "$1" "sudo df -hT"