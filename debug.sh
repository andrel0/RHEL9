#!/bin/bash

function obtener_discos_nuevos() {
    local discos_nuevos_disponibles=()

    echo "Listado de discos físicos sin particiones reconocibles por LVM o con tabla de particiones desconocida:"

    # Iterar sobre discos físicos
    for disco in $(lsblk -rno NAME,TYPE,MOUNTPOINT | awk '$2 == "disk" {print $1}'); do
        # Verificar si el disco tiene particiones reconocibles
        if [ -z "$(lsblk -rno NAME,MOUNTPOINT /dev/${disco}[0-9] 2>/dev/null)" ]; then
            # Verificar si el disco tiene una tabla de particiones desconocida o es reconocible por LVM
            if ! parted /dev/$disco print 2>/dev/null | grep -qE '(Partition Table: unknown|lvm)'; then
                echo "- $disco"
                discos_nuevos_disponibles+=("$disco")
            fi
        fi
    done

    if [ ${#discos_nuevos_disponibles[@]} -eq 0 ]; then
        echo "No se han encontrado discos físicos nuevos sin particiones reconocibles por LVM o con tabla de particiones desconocida."
    else
        echo "Discos físicos nuevos detectados sin particiones reconocibles por LVM o con tabla de particiones desconocida:"
        echo "Nombres de discos físicos nuevos: ${discos_nuevos_disponibles[@]}"
    fi
}

# Ejecutar la función principal
obtener_discos_nuevos
