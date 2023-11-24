#!/bin/bash

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
    if [ -z "$(parted /dev/$disco print 2>/dev/null | grep -E 'Partition Table:')" ]; then
        espacio_disponible=$(lsblk -o SIZE -b -n /dev/$disco)
        echo "- $disco (Espacio Disponible: $espacio_disponible bytes)"
        discos_nuevos_disponibles+=($disco)
    fi
done

if [ ${#discos_nuevos_disponibles[@]} -eq 0 ]; then
    echo "No se han encontrado discos físicos nuevos sin particiones."
else
    echo "Discos físicos nuevos detectados sin particiones:"
    # Ya no es necesario iterar sobre la variable discos_nuevos_disponibles, ya que la información se imprime en el bucle anterior
fi
