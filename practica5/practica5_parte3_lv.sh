#!/bin/bash
#755848, Cánovas, Guillermo, T, 2, B
#759934, Huszak, Ioan Paul, T, 2, B

while read -p ">" lectura
do
	
	if [ "$lectura" == "quit" ]
	then
		echo "Final"
		exit 1
	fi
	echo "$lectura"
	grupovolumen=$(echo $lectura | cut -d ','  -f1)
	volumenlogico=$(echo $lectura | cut -d ','  -f2)
	tamanyo=$(echo $lectura | cut -d ',' -f3)
	tsistemaficheros=$(echo $lectura | cut -d ',' -f4)
	directorio=$(echo $lectura | cut -d ',' -f5)

	ruta="/dev/${grupovolumen}/${volumenlogico}"
	echo $ruta
#Comprobamos si existe el grupo lógico
	exite=$( sudo vgscan | grep "$grupovolumen")

	if [ -z "$exite" ]
	then
		echo "No existe el grupo: $grupovolumen"
		exit 1

	else	
		exite=$(sudo lvscan | grep "$ruta" )
		if [  -z "$exite"  ] #Si no hay contenido en la variables es que no existe
		then #Tenemos que crear el volumen logico
			sudo lvcreate -L "$tamanyo" --name "$volumenlogico" "$grupovolumen"
			
			if [ $? -eq 0 ]; then
				sudo mkfs -t "$tsistemaficheros" "$ruta"
				if [ ! -d "$directorio" ] #Comprobamos si existe el directorio
				then	
					echo "Creando directorio: $directorio"
					sudo mkdir -p "$directorio"
				fi #Montamos el sistema de ficheros
				sudo mount -t  "$tsistemaficheros" "$ruta" "$directorio"
				ID=$(sudo blkid "$ruta" | cut -d ' ' -f2  )
				#Añadimos el volumen lógico para su correcto montaje en el arranque
				sudo su -c "echo \"$ID $directorio $tsistemaficheros errors=remount 0 2\" >> /etc/fstab"
			fi
		else #El volúmen lógico ya existía y lo extendemos
			sudo lvextend -L "$tamanyo" "$ruta"
			sudo resize2fs "$ruta"
		fi
	
	fi
done
