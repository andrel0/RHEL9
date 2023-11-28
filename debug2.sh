#!/bin/bash

function obtener_discos_nuevos() {
    local discos_nuevos_disponibles=()

    # Iterar sobre discos físicos
    while IFS= read -r disco; do
        # Verificar si el disco tiene particiones reconocibles
        if [ -z "$(lsblk -rno NAME,MOUNTPOINT /dev/${disco}[0-9] 2>/dev/null)" ]; then
            # Verificar si el disco tiene una tabla de particiones desconocida y no es reconocible por LVM
            if parted_output=$(parted /dev/$disco print 2>/dev/null | grep -E 'Partition Table: unknown'); then
                echo "$disco"
                discos_nuevos_disponibles+=("$disco")
                # Redirigir la salida de parted al archivo en /tmp
                parted /dev/$disco print 2>/dev/null > "/tmp/$disco.parted"
                echo "DEBUG: Salida de parted para $disco:"
                cat "/tmp/$disco.parted"
            fi
        fi
    done < <(lsblk -rno NAME,TYPE,MOUNTPOINT | awk '$2 == "disk" {print $1}')

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
            if [ -e "/tmp/$disco.parted" ]; then
                echo "DEBUG: Contenido de /tmp/$disco.parted antes de awk:"
                cat "/tmp/$disco.parted"
                # Mostrar la información a partir de la línea que contiene "Model:"
                awk '/Model:/{flag=1; next} flag' "/tmp/$disco.parted"
                # Puedes ajustar esto según la salida específica que deseas mostrar
            else
                echo "No existen discos físicos sin tablas de particiones."
            fi
        done
    fi
}

# Ejecutar la función principal y obtener los nombres de los discos nuevos
nombres_discos_nuevos=($(obtener_discos_nuevos))

# Pasar los nombres de los discos nuevos a la función para mostrar información adicional
mostrar_informacion_adicional "${nombres_discos_nuevos[@]}"

# Eliminar archivos temporales
rm /tmp/*.parted








[root@rhel9 ~]# ./debug3.sh

Información adicional sobre los discos físicos nuevos:

sdc:
DEBUG: Contenido de /tmp/sdc.parted antes de awk:
Model: VMware Virtual disk (scsi)
Disk /dev/sdc: 1074MB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:
Disk /dev/sdc: 1074MB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:

DEBUG::
No existen discos físicos sin tablas de particiones.

Salida:
No existen discos físicos sin tablas de particiones.

de:
No existen discos físicos sin tablas de particiones.

parted:
No existen discos físicos sin tablas de particiones.

para:
No existen discos físicos sin tablas de particiones.

sdc::
No existen discos físicos sin tablas de particiones.

:
No existen discos físicos sin tablas de particiones.

Model::
No existen discos físicos sin tablas de particiones.

VMware:
No existen discos físicos sin tablas de particiones.

Virtual:
No existen discos físicos sin tablas de particiones.

disk:
No existen discos físicos sin tablas de particiones.

(scsi):
No existen discos físicos sin tablas de particiones.

Disk:
No existen discos físicos sin tablas de particiones.

/dev/sdc::
No existen discos físicos sin tablas de particiones.

1074MB:
No existen discos físicos sin tablas de particiones.

Sector:
No existen discos físicos sin tablas de particiones.

size:
No existen discos físicos sin tablas de particiones.

(logical/physical)::
No existen discos físicos sin tablas de particiones.

512B/512B:
No existen discos físicos sin tablas de particiones.

Partition:
No existen discos físicos sin tablas de particiones.

Table::
No existen discos físicos sin tablas de particiones.

unknown:
No existen discos físicos sin tablas de particiones.

Disk:
No existen discos físicos sin tablas de particiones.

Flags::
No existen discos físicos sin tablas de particiones.

sdc:
DEBUG: Contenido de /tmp/sdc.parted antes de awk:
Model: VMware Virtual disk (scsi)
Disk /dev/sdc: 1074MB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:
Disk /dev/sdc: 1074MB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:

