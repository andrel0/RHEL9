#!/bin/bash

# Función para obtener discos nuevos sin particiones reconocibles
function obtener_discos_nuevos() {
    local discos_nuevos_globales=()

    echo "Listado de discos físicos sin particiones reconocibles por LVM o con tabla de particiones desconocida:"
    discos_nuevos_disponibles=($(lsblk -rno NAME,TYPE,MOUNTPOINT | awk '$2 == "disk" && $3 == "" {print $1}'))

    if [ ${#discos_nuevos_disponibles[@]} -eq 0 ]; then
        echo "No se han encontrado discos físicos nuevos sin particiones reconocibles por LVM o con tabla de particiones desconocida."
    else
        echo "Discos físicos nuevos detectados sin particiones reconocibles por LVM o con tabla de particiones desconocida:"
        echo "Nombres de discos físicos nuevos: ${discos_nuevos_disponibles[@]}"
        discos_nuevos_globales=("${discos_nuevos_disponibles[@]}")
    fi

    echo "${discos_nuevos_globales[@]}"
}

# Función para mostrar información adicional sobre los discos
function mostrar_informacion_adicional() {
    local nombres_discos_nuevos=("$@")

    if [ ${#nombres_discos_nuevos[@]} -gt 0 ]; then
        echo -e "\nInformación adicional sobre los discos físicos nuevos:"
        for disco in "${nombres_discos_nuevos[@]}"; do
            echo -e "\n$disco:"
            if parted /dev/$disco print 2>/dev/null | grep -qE '(Partition Table: unknown|lvm)'; then
                parted /dev/$disco print
            else
                echo "El disco no tiene una tabla de particiones reconocible o es reconocible por LVM."
            fi
        done
    fi
}

# Ejecutar la función principal
nombres_discos_nuevos=($(obtener_discos_nuevos))
mostrar_informacion_adicional "${nombres_discos_nuevos[@]}"

