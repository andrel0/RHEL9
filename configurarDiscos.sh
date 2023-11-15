#!/bin/bash

mostrar_discos() {
    echo "Listado de discos:"
    fdisk -l
}

actualizar_discos() {
    echo -e "\nActualizando información de discos..."
    partprobe
    echo "¡Información de discos actualizada!"
}

buscar_espacio_no_asignado() {
    echo -e "\nBuscando espacio no asignado..."
    lvdisplay
}

listar_particiones_expansibles() {
    echo -e "\nParticiones LVM que pueden expandirse:"
    particiones_expansibles=($(lvdisplay | awk '/LV Path/ {path=$3} /LV Size/ {size=$3} /Allocatable/ {if ($2=="yes") print path, size}' | cut -d' ' -f1))

    if [ ${#particiones_expansibles[@]} -eq 0 ]; then
        echo "No hay particiones LVM disponibles para expandirse."
        return
    fi

    for ((i=0; i<${#particiones_expansibles[@]}; i++)); do
        echo "$((i+1)). ${particiones_expansibles[i]}"
    done
}

expandir_particion() {
    listar_particiones_expansibles
    PS3="Seleccione el número de la partición que desea expandir: "
    select particion in "${particiones_expansibles[@]}"; do
        if [ -n "$particion" ]; then
            lvextend -l +100%FREE /dev/mapper/$particion
            resize2fs /dev/mapper/$particion
            echo -e "\nLa partición LVM $particion se ha expandido al 100% del espacio disponible."
            break
        else
            echo "Opción no válida. Intente de nuevo."
        fi
    done
}

while true; do
    echo -e "\n--- Menú Principal ---"
    echo "1. Mostrar discos"
    echo "2. Actualizar información de discos"
    echo "3. Buscar espacio no asignado"
    echo "4. Listar particiones LVM que pueden expandirse"
    echo "5. Expandir partición LVM"
    echo "6. Refrescar datos de particiones"
    echo "7. Salir"

    read -p "Seleccione una opción (1-7): " opcion

    case $opcion in
        1) mostrar_discos ;;
        2) actualizar_discos ;;
        3) buscar_espacio_no_asignado ;;
        4) listar_particiones_expansibles ;;
        5) expandir_particion ;;
        6) continue ;;
        7) echo "Saliendo del script. ¡Hasta luego!"; exit ;;
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac
done
