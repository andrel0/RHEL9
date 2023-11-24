#!/bin/bash

# Limpiar la pantalla
clear

# Mostrar el listado de discos físicos
echo "Listado de discos físicos:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Actualizar información de discos
echo -e "\nActualizando información de discos..."

# Escanear y agregar discos físicos detectados localmente en VMware
echo "Escaneando y agregando discos físicos detectados localmente en VMware..."
rescan-scsi-bus.sh > /dev/null  # Se ejecuta sin mostrar la salida en pantalla
partprobe > /dev/null  # Se ejecuta sin mostrar la salida en pantalla

# Obtener la lista de discos físicos nuevos sin particiones ni LVM
discos_nuevos_disponibles=()

while read -r disco tipo; do
    # Asegúrate de que el disco no tenga particiones ni LVM
    if [ "$tipo" == "disk" ] && [ -z "$(lsblk /dev/$disco -o NAME | tail -n +2)" ]; then
        espacio_disponible=$(lsblk -o SIZE -b -n /dev/$disco)
        echo "- $disco (Espacio Disponible: $espacio_disponible bytes)"
        discos_nuevos_disponibles+=($disco)
    fi
done < <(lsblk -o NAME,TYPE | tail -n +2)

if [ ${#discos_nuevos_disponibles[@]} -eq 0 ]; then
    echo "No se han encontrado discos físicos nuevos con espacio disponible y sin particiones ni LVM asignados."
else
    echo "Discos físicos nuevos detectados con espacio disponible y sin particiones ni LVM asignados:"
    # Ya no es necesario iterar sobre la variable discos_nuevos_disponibles, ya que la información se imprime en el bucle anterior
fi
