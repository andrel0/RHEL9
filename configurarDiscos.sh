#!/bin/bash

# Verificar si se ejecuta como root
if [ "$(id -u)" != "0" ]; then
    echo "Este script debe ejecutarse como root. Por favor, use sudo o inicie sesión como root."
    exit 1
fi

limpiar_pantalla() {
    clear
}

mostrar_discos() {
    echo "Listado de discos:"
    fdisk -l
}

actualizar_discos() {
    echo -e "\nActualizando información de discos..."
    partprobe
    echo "¡Información de discos actualizada!"
}

listar_particiones() {
    limpiar_pantalla
    echo -e "Listado de particiones:"
    lvdisplay | awk '/LV Path/ {print $3}'
}

listar_particiones_expansibles() {
    limpiar_pantalla
    echo -e "Particiones LVM que pueden expandirse:"
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
    limpiar_pantalla
    echo -e "--- Menú Principal ---"
    echo "1. Mostrar discos"
    echo "2. Refrescar información de discos"
    echo "3. Listar todas las particiones"
    echo "4. Listar particiones LVM que pueden expandirse"
    echo "5. Buscar espacio no asignado"
    echo "6. Expandir partición LVM"
    echo "7. Salir"

    read -p "Seleccione una opción (1-7): " opcion

    case $opcion in
        1) mostrar_discos ;;
        2) actualizar_discos ;;
        3) listar_particiones ;;
        4) listar_particiones_expansibles ;;
        5) buscar_espacio_no_asignado ;;
        6) expandir_particion ;;
        7) echo "Saliendo del script. ¡Hasta luego!"; exit ;;
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac

    read -p "Presione Enter para volver al menú..."
done
