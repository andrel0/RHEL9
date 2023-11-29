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



Escaneando discos físicos...
Warning: Not all of the space available to /dev/sda appears to be used, you can fix the GPT to use all of the space (an extra 4194304 blocks) or continue with the current setting?
Warning: Not all of the space available to /dev/sdb appears to be used, you can fix the GPT to use all of the space (an extra 4194304 blocks) or continue with the current setting?
Warning: Unable to open /dev/sr0 read-write (Read-only file system).  /dev/sr0 has been opened read-only.
Información sobre los discos físicos y espacio disponible:
NAME                            SIZE FSTYPE      MOUNTPOINT
sda                              32G
├─sda1                          600M vfat        /boot/efi
├─sda2                            1G xfs         /boot
└─sda3                         28.4G LVM2_member
  ├─vg_rhel_rhel9-root           20G xfs         /
  ├─vg_rhel_rhel9-swap            2G swap        [SWAP]
  └─vg_rhel_rhel9-home          6.4G xfs         /home
sdb                              12G
└─sdb1                           10G LVM2_member
  ├─vg_rhel_rhel9_dinamico-var    5G xfs         /var
  └─vg_rhel_rhel9_dinamico-tmp    5G xfs         /tmp
sr0                             8.9G iso9660
1) vg_rhel_rhel9
2) vg_rhel_rhel9_dinamico
Seleccione el número del Volume Group (VG) que desea expandir: 2
1) tmp
2) var
Seleccione el número del Logical Volume (LV) que desea expandir: 1
  --- Logical volume ---
  LV Path                /dev/vg_rhel_rhel9_dinamico/tmp
  LV Name                tmp
  VG Name                vg_rhel_rhel9_dinamico
  LV UUID                XG66NO-V2sX-sAUo-Fbbh-mhLo-4Nz3-n5gqfa
  LV Write Access        read/write
  LV Creation host, time rhel9.2, 2023-09-18 17:30:40 -0300
  LV Status              available
  # open                 1
  LV Size                <5.00 GiB
  Current LE             1279
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:3

Ingrese la cantidad de espacio adicional en megabytes para tmp: 2048
  Insufficient free space: 512 extents needed, but only 0 available
resize2fs 1.46.5 (30-Dec-2021)
resize2fs: Bad magic number in super-block while trying to open /dev/vg_rhel_rhel9_dinamico/tmp
Couldn't find valid filesystem superblock.

El Logical Volume (LV) tmp en el Volume Group (VG) vg_rhel_rhel9_dinamico se ha expandido en 2048 megabytes en el disco   /dev/sdb1(1280).
Seleccione el número del Logical Volume (LV) que desea expandir: ^C

