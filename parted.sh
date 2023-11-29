#!/bin/bash

# Obtener información de la tabla de particiones
part_info=$(parted /dev/sdb print)

# Extraer el número de partición que deseas ajustar
echo "$part_info" | grep -E '^[[:space:]]*[0-9]+' | awk '{print $1}'

# Solicitar al usuario el número de partición
read -p "Ingrese el número de partición que desea redimensionar: " partition_number

# Solicitar al usuario el nuevo tamaño
read -p "Ingrese el nuevo tamaño para la partición: " new_size

# Ejecutar parted y redirigir la entrada estándar
parted /dev/sdb <<EOF
print
fix
resizepart $partition_number $new_size
quit
EOF
