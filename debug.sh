#!/bin/bash

# Limpiar la pantalla
clear

# Mostrar el listado de discos físicos
echo "Listado de discos físicos:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Actualizar información de discos
echo -e "\nActualizando información de discos..."

# Escanear y agregar discos físicos detectados localmente en VMware
echo "Escaneando y agregando discos físicos detectados localmente en VMware..."
rescan-scsi-bus.sh > /dev/null  # Se ejecuta sin mostrar la salida en pantalla
partprobe > /dev/null  # Se ejecuta sin mostrar la salida en pantalla

# Obtener la lista de discos físicos nuevos sin particiones ni LVM
discos_nuevos_disponibles=()

while read -r disco tipo; do
    # Asegúrate de que el disco no tenga particiones
    if [ "$tipo" == "disk" ] && [ -z "$(fdisk -l /dev/$disco 2>/dev/null | grep -E '/dev/'$disco':[0-9]+')" ]; then
        espacio_disponible=$(lsblk -o SIZE -b -n /dev/$disco)
        echo "- $disco (Espacio Disponible: $espacio_disponible bytes)"
        discos_nuevos_disponibles+=($disco)
    fi
done < <(lsblk -o NAME,TYPE | tail -n +2)

if [ ${#discos_nuevos_disponibles[@]} -eq 0 ]; then
    echo "No se han encontrado discos físicos nuevos con espacio disponible y sin particiones ni LVM asignados."
else
    echo "Discos físicos nuevos detectados con espacio disponible y sin particiones ni LVM asignados:"
    # Ya no es necesario iterar sobre la variable discos_nuevos_disponibles, ya que la información se imprime en el bucle anterior
fi

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
- sda (Espacio Disponible: 32212254720
  629145600
 1073741824
30507270144
21474836480
 2147483648
 6878658560 bytes)
- sdb (Espacio Disponible: 10737418240
10735321088
 5368709120
 5364514816 bytes)
- sdc (Espacio Disponible: 1073741824 bytes)
./debug.sh: line 35: syntax error: unexpected end of file
