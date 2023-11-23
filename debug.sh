#!/bin/bash

# Declaración variables global para almacenar la lista de discos nuevos
discos_nuevos_disponibles=()

limpiar_pantalla() {
    clear
}

refrescar_y_detectar_discosnuevos() {
    limpiar_pantalla
    echo "Listado de discos físicos:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    echo -e "\nActualizando información de discos..."
    
    # Escanear y agregar discos físicos detectados localmente en VMware
    echo "Escaneando y agregando discos físicos detectados localmente en VMware..."
    rescan-scsi-bus.sh > /dev/null  # Se ejecuta sin mostrar la salida en pantalla
    partprobe > /dev/null  # Se ejecuta sin mostrar la salida en pantalla

    # Obtener la lista de discos físicos nuevos sin particiones ni LVM
    discos_nuevos_disponibles=()

    while read -r disco tipo; do
        # Asegúrate de que el disco no tenga una tabla de particiones conocida
        if ! parted /dev/$disco print | grep -q "Partition Table: unknown"; then
            espacio_disponible=$(lsblk -o SIZE -b -n /dev/$disco)
            echo "- $disco (Espacio Disponible: $espacio_disponible bytes)"
            discos_nuevos_disponibles+=($disco)
        fi
    done < <(lsblk -o NAME,TYPE | awk '$2 == "disk" && system("lvdisplay " $1 " > /dev/null") == 1 && system("vgdisplay " $1 " > /dev/null") == 1 {print $1, $2}')

    if [ ${#discos_nuevos_disponibles[@]} -eq 0 ]; then
        echo "No se han encontrado discos físicos nuevos con espacio disponible y sin particiones ni LVM asignados."
        return
    fi

    echo "Discos físicos nuevos detectados con espacio disponible y sin particiones ni LVM asignados:"
    # Ya no es necesario iterar sobre la variable discos_nuevos_disponibles, ya que la información se imprime en el bucle anterior
}

# Ejemplo de uso:
# refrescar_y_detectar_discosnuevos
# echo "Discos nuevos disponibles: ${discos_nuevos_disponibles[@]}"
