#!/bin/bash
#755848, Cánovas, Guillermo, T, 2, B
#759934, Huszak, Ioan Paul, T, 2, B

if [ $# -lt 2 ] #Revisar que haya al menos una partición para añadir
then
	echo "Numero incorrecto de parametros"
	exit 85
fi

grupo="$1"
shift 1 
particiones=$@

for file in $particiones #Añadimos las particiones
do
	echo "$file"
     	sudo pvcreate -f "${file}"
	if [ $? -eq 5 ] #Revisamos que no haya habido ningun problema
	then
		echo "Particion: $particiones montada o ya forma parte de un grupo volumen"
	else
		sudo vgextend "${grupo}" "${file}" #Extendemos el grupo volumen
	fi
done