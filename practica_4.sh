#!/bin/bash
# Eduardo Gimeno 721615

# Comprobar número de parámetros
if [ "$#" != "3" ]
then
  echo "Numero incorrecto de parametros"
  exit 1
fi

# Comprobar si la opción introducida es correcta
if [ "$1" != "-a" -a "$1" != "-s" ]
then
  echo "Opcion invalida" 1>&2
  exit 1
fi

# Ruta de la clave privada
keypath=/home/"$USER"/.ssh/id_as_ed25519

cat "$3" | while read ip
do
  # Comprobar si se puede establecer conexión con la máquina, si no, se aborta ejecución
  ssh -q -n -i "$keypath" user@"$ip" exit
  if [ "$?" -ne 0 ]
  then
    echo "$ip no es accesible"
    exit 1
  fi
  
  # Crear, si no existía ya, el directorio para guardar las copias de los home de los usuarios
  ssh -q -n -i "$keypath" user@"$ip" sudo mkdir -p /extra/backup > /dev/null 2>&1

  cat "$2" | while read line
  do
    # Extraer del fichero el id del usuario, contraseña y nombre
    username=$(echo "$line" | cut -d ',' -f 1)
    password=$(echo "$line" | cut -d ',' -f 2)
    name=$(echo "$line" | cut -d ',' -f 3)

    # Borrar usuarios
    if [ "$1" = "-s" ]
    then
      # Comporbar si el usuario existe
      if ssh -q -n -i "$keypath" user@"$ip" id "$iduser" > /dev/null 2>&1
      then
	# Encontrar su directorio home
        homeuser=$(ssh -q -n -i "$keypath" user@"$ip" cat /etc/passwd | grep "$username" | cut -d ':' -f 6)
	homeuser1="${homeuser%/*}"
        homeuser2="${homeuser##*/}"
        ad=$(ssh -q -n -i "$keypath" user@"$ip" date "+%Y-%m-%d")
	# Bloquear la cuenta para que no pueda modificar nada mientras se hace el backup
        ssh -q -n -i "$keypath" user@"$ip" sudo usermod -e "$ad" "$username" > /dev/null 2>&1
	# Se crea el tar y si tiene éxito de borra al usuario
        if ssh -q -n -i "$keypath" user@"$ip" sudo tar cf "/extra/backup/${username}.tar" -C "$homeuser1" "$homeuser2" > /dev/null 2>&1
        then
	  ssh -q -n -i "$keypath" user@"$ip" sudo userdel -r "$username" > /dev/null 2>&1
        fi
      fi
    else
      # Añadir usuarios
      # Comprobar que ninguno de los tres campos contenga la cadena vacía
      if [ -z "$username" -o -z "$password" -o -z "$name" ]
      then
        echo "Campo invalido"
        exit 1
      fi
      
      # Añadir al usuario
      if ssh -q -n -i "$keypath" user@"$ip" sudo useradd -m -K UID_MIN=1815 -c "$name" -k /etc/skel -U "$username" > /dev/null 2>&1
      then
	# Establecer su contraseña
        ssh -q -n -i "$keypath" user@"$ip" echo "$username:$password" | ssh -q -n -i "$keypath" user@"$ip" sudo chpasswd > /dev/null 2>&1
	# Por un mínimo de 30 días
        if ssh -q -n -i "$keypath" user@"$ip" sudo chage -m 30 "$username" > /dev/null 2>&1
        then
	  echo "$name ha sido creado"
        fi
      else
        echo "El usuario $username ya existe"
      fi
    fi
  done
done
