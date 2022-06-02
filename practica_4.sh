#!/bin/bash
#755848, Cánovas, Guillermo, T, 2, B
#759934, Huszak, Ioan Paul, T, 2, B

#Uso: sudo ./practica_4.sh  [-a|-s] <fichero_usuarios> <fichero_máquinas> 
#OPCIONES
#   -a	 Añade los usuarios del fichero al sistema
#   -s	 Elimina los usuarios del fichero del sistema
#<fichero_usuarios>
#  El fichero, para añadir debe contener por cada linea:
#	nombre,contraseña,nombreCompleto
#  Para eliminar, puede o no contener la contraseña:
#       nombre
#<fichero_máquinas>
#  El fichero debe contener una direccion ip por cada linea
#
#Explicacion:Script para añadir o eliminar los usuarios que hay en el
#            FICHERO_USUARIOS en todas las ips de las maquinas que ha
#            en <fichero_máquinas>

borrarUsuario(){ #Opcion eliminar usuario
    oldIFS=$IFS #Se guarda el antiguo IFS
    IFS=,
	while read ip
	do
		ping -c 1 $ip > /dev/null #Comprobando si $IP es accesible
		if [ $? -ne 0 ]
		then
			echo "$ip no es accesible"
		else
			ssh -n as@$ip "sudo mkdir -p /extra/backup"
			while read nombre ignore #Leemos los nombres para eliminar
			do
				ssh -n as@$ip "id $nombre 2> /dev/null > /dev/null"
				if [ $? -eq 0 ]
				then
					uhome=$(ssh -n as@$ip "cat /etc/passwd | grep "${nombre}:" | cut -d ':' -f 6") #Se comprueba cual es un directorio home/usuario
					ssh -n as@$ip "sudo tar -cvf /extra/backup/${nombre}.tar $uhome 2> /dev/null > /dev/null" #Se hace el backup 
					if [ $? -eq 0 ]
					then
						ssh -n as@$ip "sudo userdel -r $nombre 2> /dev/null"
					fi
				fi
			done < $1
		fi
	done < $2
    IFS=$oldIFS
}

anyadirUsuario(){ #Opcion añadir usuario
    oldIFS=$IFS #Se guarda el antiguo IFS
    IFS=,
	while read ip
	do
		ping -c 1 $ip > /dev/null #Comprobando si $IP es accesible
		if [ $? -ne 0 ]
		then
			echo "$ip no es accesible"
		else
			while read nombre contrasena nomC #Leemos los nombres y passwords del fichero
			do
				if [[ -z "$nombre" || -z "$contrasena" || -z "${nomC}" ]]
				then
					echo "Campo invalido"
				else
					ssh -n  as@$ip "sudo useradd -c "$nomC" $nombre -m -k /etc/skel -K UID_MIN=1815 -U 2> /dev/null"
					anyadido=$?
					if [ $anyadido -eq 9 ]
					then
							echo "El usuario $nombre ya existe"
					elif [ $anyadido -eq 0 ]
					then
						ssh -n as@$ip "sudo usermod -f0 $nombre"
						ssh -n as@$ip "echo "${nombre}:$contrasena" | sudo chpasswd"
						ssh -n as@$ip "sudo passwd -x30 $nombre > /dev/null"
						echo "$nomC ha sido creado"
					fi
				fi
			done < $1
		fi
	done < $2
    IFS=$oldIFS
}



if [ $(id -u) -eq 0 ]
then
     if [ $# -ne 3 ] #Comprobamos si tiene tres parametros
     then
            echo "Numero incorrecto de parametros"
    else
        if [ $1 == "-a" ]
        then
            anyadirUsuario $2 $3
        elif [ $1 == "-s" ]
        then
            borrarUsuario $2 $3
        else
            echo "Opcion invalida" >&2
        fi
    fi
else
    echo "Este script necesita privilegios de administracion"
    exit 1
fi
