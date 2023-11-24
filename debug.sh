#!/bin/bash

# Declaración de variables global
discos_nuevos_globales=()

# Limpiar la pantalla
clear

# Mostrar el listado de discos físicos
echo "Listado de discos físicos:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Actualizar información de discos
echo -e "\nActualizando información de discos..."

# Obtener la lista de discos físicos nuevos sin particiones
discos_nuevos_disponibles=()

for disco in $(lsblk -o NAME,TYPE | awk '$2 == "disk" {print $1}'); do
    # Asegúrate de que el disco no tenga particiones
    if [ -n "$(parted /dev/$disco print 2>/dev/null | grep 'Partition Table: unknown')" ]; then
        espacio_disponible=$(lsblk -o SIZE -b -n /dev/$disco)
        echo "- $disco (Espacio Disponible: $espacio_disponible bytes)"
        discos_nuevos_disponibles+=($disco)
    fi
done

if [ ${#discos_nuevos_disponibles[@]} -eq 0 ]; then
    echo "No se han encontrado discos físicos nuevos sin particiones."
else
    echo "Discos físicos nuevos detectados sin particiones:"
    # Guardar todos los discos en el array global
    discos_nuevos_globales=("${discos_nuevos_disponibles[@]}")
    echo "Nombres de discos físicos nuevos: ${discos_nuevos_globales[@]}"
fi

# Mostrar información adicional sobre los discos detectados
if [ ${#discos_nuevos_globales[@]} -gt 0 ]; then
    echo -e "\nInformación adicional sobre los discos físicos nuevos:"
    for disco in "${discos_nuevos_globales[@]}"; do
        echo -e "\n$disco:"
        parted  /dev/$disco print
        # Puedes agregar más comandos para obtener información adicional según tus necesidades
    done
fi
