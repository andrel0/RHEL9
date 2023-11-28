#!/bin/bash

function obtener_discos_nuevos() {
    local discos_nuevos_disponibles=()

    echo "Listado de discos físicos sin particiones reconocibles por LVM o con tabla de particiones desconocida:"

    for disco in /sys/class/block/sd*; do
        # Verificar si el disco tiene particiones reconocibles
        if [ ! -d "$disco"/[a-z]* ]; then
            # Verificar si el disco tiene una tabla de particiones desconocida o es reconocible por LVM
            if ! parted /dev/$(basename $disco) print 2>/dev/null | grep -qE '(Partition Table: unknown|lvm)'; then
                echo "- $(basename $disco)"
                discos_nuevos_disponibles+=("$(basename $disco)")
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
