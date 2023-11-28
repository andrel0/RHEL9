#!/bin/bash

# Desvincular las variables globales al inicio del script
unset nombres_discos_nuevos

function obtener_discos_nuevos() {
    local discos_nuevos_disponibles=()

    echo "Listado de discos físicos sin particiones reconocibles por LVM o con tabla de particiones desconocida:"

    # Iterar sobre discos físicos
    for disco in $(lsblk -rno NAME,TYPE,MOUNTPOINT | awk '$2 == "disk" {print $1}'); do
        # Verificar si el disco tiene particiones reconocibles
        if [ -z "$(lsblk -rno NAME,MOUNTPOINT /dev/${disco}[0-9] 2>/dev/null)" ]; then
            # Verificar si el disco tiene una tabla de particiones desconocida y no es reconocible por LVM
            if parted_output=$(parted /dev/$disco print 2>/dev/null | grep -E 'Partition Table: unknown' | grep -v 'Flags'); then
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

    # Retornar el array de discos físicos nuevos
    echo "${discos_nuevos_disponibles[@]}"
}

function mostrar_informacion_adicional() {
    local nombres_discos_nuevos=("$@")

    if [ ${#nombres_discos_nuevos[@]} -gt 0 ]; then
        echo -e "\nInformación adicional sobre los discos físicos nuevos:"
        for disco in "${nombres_discos_nuevos[@]}"; do
            echo -e "\n$disco:"
            
            # Verificar si el disco tiene una tabla de particiones reconocible
            if parted /dev/$disco print 2>/dev/null | grep -E 'Partition Table: unknown'; then
                echo "DEBUG: Se detectó una tabla de particiones desconocida"
                parted /dev/$disco print
                # Puedes agregar más comandos para obtener información adicional
            else
                echo "DEBUG: No se detectó una tabla de particiones desconocida."
            fi
        done
    fi
}

# Ejecutar la función principal y obtener los nombres de los discos nuevos
nombres_discos_nuevos=($(obtener_discos_nuevos))

# Pasar los nombres de los discos nuevos a la función para mostrar información adicional
mostrar_informacion_adicional "${nombres_discos_nuevos[@]}"



[root@rhel9 ~]# ./debug.sh

Información adicional sobre los discos físicos nuevos:

Listado:
DEBUG: No se detectó una tabla de particiones desconocida.

de:
DEBUG: No se detectó una tabla de particiones desconocida.

discos:
DEBUG: No se detectó una tabla de particiones desconocida.

físicos:
DEBUG: No se detectó una tabla de particiones desconocida.

sin:
DEBUG: No se detectó una tabla de particiones desconocida.

particiones:
DEBUG: No se detectó una tabla de particiones desconocida.

reconocibles:
DEBUG: No se detectó una tabla de particiones desconocida.

por:
DEBUG: No se detectó una tabla de particiones desconocida.

LVM:
DEBUG: No se detectó una tabla de particiones desconocida.

o:
DEBUG: No se detectó una tabla de particiones desconocida.

con:
DEBUG: No se detectó una tabla de particiones desconocida.

tabla:
DEBUG: No se detectó una tabla de particiones desconocida.

de:
DEBUG: No se detectó una tabla de particiones desconocida.

particiones:
DEBUG: No se detectó una tabla de particiones desconocida.

desconocida::
DEBUG: No se detectó una tabla de particiones desconocida.

-:
DEBUG: No se detectó una tabla de particiones desconocida.

sdc:
Partition Table: unknown
DEBUG: Se detectó una tabla de particiones desconocida
Error: /dev/sdc: unrecognised disk label
Model: VMware Virtual disk (scsi)
Disk /dev/sdc: 1074MB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:

Discos:
DEBUG: No se detectó una tabla de particiones desconocida.

físicos:
DEBUG: No se detectó una tabla de particiones desconocida.

nuevos:
DEBUG: No se detectó una tabla de particiones desconocida.

detectados:
DEBUG: No se detectó una tabla de particiones desconocida.

sin:
DEBUG: No se detectó una tabla de particiones desconocida.

particiones:
DEBUG: No se detectó una tabla de particiones desconocida.

reconocibles:
DEBUG: No se detectó una tabla de particiones desconocida.

por:
DEBUG: No se detectó una tabla de particiones desconocida.

LVM:
DEBUG: No se detectó una tabla de particiones desconocida.

o:
DEBUG: No se detectó una tabla de particiones desconocida.

con:
DEBUG: No se detectó una tabla de particiones desconocida.

tabla:
DEBUG: No se detectó una tabla de particiones desconocida.

de:
DEBUG: No se detectó una tabla de particiones desconocida.

particiones:
DEBUG: No se detectó una tabla de particiones desconocida.

desconocida::
DEBUG: No se detectó una tabla de particiones desconocida.

Nombres:
DEBUG: No se detectó una tabla de particiones desconocida.

de:
DEBUG: No se detectó una tabla de particiones desconocida.

discos:
DEBUG: No se detectó una tabla de particiones desconocida.

físicos:
DEBUG: No se detectó una tabla de particiones desconocida.

nuevos::
DEBUG: No se detectó una tabla de particiones desconocida.

sdc:
Partition Table: unknown
DEBUG: Se detectó una tabla de particiones desconocida
Error: /dev/sdc: unrecognised disk label
Model: VMware Virtual disk (scsi)
Disk /dev/sdc: 1074MB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:

sdc:
Partition Table: unknown
DEBUG: Se detectó una tabla de particiones desconocida
Error: /dev/sdc: unrecognised disk label
Model: VMware Virtual disk (scsi)
Disk /dev/sdc: 1074MB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:

