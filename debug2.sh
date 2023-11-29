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
                # Mostrar la información relevante entre "Model:" y "Disk Flags:"
                awk '/Model:/{model_found=1} /Disk Flags:/{print; model_found=0} model_found && !/Disk Flags:/{print}' "/tmp/$disco.parted"
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

nombres_discos_nuevos=($(obtener_discos_nuevos))
mostrar_informacion_adicional "${nombres_discos_nuevos[@]}"
