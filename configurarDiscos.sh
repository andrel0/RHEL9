#!/bin/bash

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

refrescar_datos_particiones() {
    limpiar_pantalla
    actualizar_discos
    buscar_espacio_no_asignado
}

listar_particiones() {
    limpiar_pantalla
    echo -e "Listado de particiones:"
    lvdisplay
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

buscar_espacio_no_asignado() {
    echo -e "\nBuscando espacio no asignado..."
    lvdisplay
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
    echo "3. Refrescar datos de particiones"
    echo "4. Listar todas las particiones"
    echo "5. Listar particiones LVM que pueden expandirse"
    echo "6. Buscar espacio no asignado"
    echo "7. Expandir partición LVM"
    echo "8. Salir"

    read -p "Seleccione una opción (1-8): " opcion

    case $opcion in
        1) mostrar_discos ;;
        2) actualizar_discos ;;
        3) refrescar_datos_particiones ;;
        4) listar_particiones ;;
        5) listar_particiones_expansibles ;;
        6) buscar_espacio_no_asignado ;;
        7) expandir_particion ;;
        8) echo "Saliendo del script. ¡Hasta luego!"; exit ;;
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac

    read -p "Presione Enter para volver al menú..."
done
