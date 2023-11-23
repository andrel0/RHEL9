#! /bin/bash

    echo "Listado de discos físicos:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    echo -e "\nActualizando información de discos..."
    
    # Escanear y agregar discos físicos detectados localmente en VMware
    echo "Escaneando y agregando discos físicos detectados localmente en VMware..."
    rescan-scsi-bus.sh > /dev/null  # Se ejecuta sin mostrar la salida en pantalla
    partprobe > /dev/null  # Se ejecuta sin mostrar la salida en pantalla

    # Obtener la lista de discos físicos nuevos sin particiones ni LVM
discos_nuevos_disponibles=($(lsblk -o NAME,TYPE | awk '$2 == "disk" && system("vgdisplay " $1 " > /dev/null") == 1 && system("parted /dev/" $1 " print | grep -q \x27^$\x27") == 0 {print $1}'))

    echo "Lista de discos obtenida: ${discos_nuevos_disponibles[@]}"

    if [ ${#discos_nuevos_disponibles[@]} -eq 0 ]; then
        echo "No se han encontrado discos físicos nuevos con espacio disponible y sin particiones ni LVM asignados."
        return
    fi

    echo "Discos físicos nuevos detectados con espacio disponible y sin particiones ni LVM asignados:"
    for disco in "${discos_nuevos_disponibles[@]}"; do
        # Asegúrate de que el disco no tenga una tabla de particiones conocida
        if ! parted /dev/$disco print | grep -q "Partition Table: unknown"; then
            espacio_disponible=$(lsblk -o SIZE -b -n /dev/$disco)
            echo "- $disco (Espacio Disponible: $espacio_disponible bytes)"
        fi
    done


    Listado de discos físicos:
NAME                            SIZE TYPE MOUNTPOINT
sda                              30G disk
├─sda1                          600M part /boot/efi
├─sda2                            1G part /boot
└─sda3                         28.4G part
  ├─vg_rhel_rhel9-root           20G lvm  /
  ├─vg_rhel_rhel9-swap            2G lvm  [SWAP]
  └─vg_rhel_rhel9-home          6.4G lvm  /home
sdb                              10G disk
└─sdb1                           10G part
  ├─vg_rhel_rhel9_dinamico-var    5G lvm  /var
  └─vg_rhel_rhel9_dinamico-tmp    5G lvm  /tmp
sdc                               1G disk
sr0                             8.9G rom

Actualizando información de discos...
Escaneando y agregando discos físicos detectados localmente en VMware...
Warning: Unable to open /dev/sr0 read-write (Read-only file system).  /dev/sr0 has been opened read-only.
./debug.sh: line 27: unexpected EOF while looking for matching `"'
./debug.sh: line 30: syntax error: unexpected end of file

