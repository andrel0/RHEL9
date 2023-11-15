#!/bin/bash

mostrar_discos() {
    echo -e "\e[1;32mListado de discos:\e[0m"
    fdisk -l
}

actualizar_discos() {
    echo -e "\n\e[1;32mActualizando información de discos...\e[0m"
    partprobe
    echo -e "\e[1;34m¡Información de discos actualizada!\e[0m"
}

buscar_espacio_no_asignado() {
    echo -e "\n\e[1;32mBuscando espacio no asignado...\e[0m"
    lvdisplay
}

listar_particiones_expansibles() {
    echo -e "\n\e[1;32mParticiones LVM que pueden expandirse:\e[0m"
    particiones_expansibles=($(lvdisplay | awk '/LV Path/ {path=$3} /LV Size/ {size=$3} /Allocatable/ {if ($2=="yes") print path, size}' | cut -d' ' -f1))

    if [ ${#particiones_expansibles[@]} -eq 0 ]; then
        echo -e "\e[1;34mNo hay particiones LVM disponibles para expandirse.\e[0m"
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
            echo -e "\n\e[1;34mLa partición LVM $particion se ha expandido al 100% del espacio disponible.\e[0m"
            break
        else
            echo -e "\e[1;31mOpción no válida. Intente de nuevo.\e[0m"
        fi
    done
}

while true; do
    echo -e "\n--- \e[1;33mMenú Principal\e[0m ---"
    echo "1. \e[1;36mMostrar discos\e[0m"
    echo "2. \e[1;36mActualizar información de discos\e[0m"
    echo "3. \e[1;36mBuscar espacio no asignado\e[0m"
    echo "4. \e[1;36mListar particiones LVM que pueden expandirse\e[0m"
    echo "5. \e[1;36mExpandir partición LVM\e[0m"
    echo "6. \e[1;36mRefrescar datos de particiones\e[0m"
    echo "7. \e[1;31mSalir\e[0m"

    read -p "Seleccione una opción (1-7): " opcion

    case $opcion in
        1) mostrar_discos ;;
        2) actualizar_discos ;;
        3) buscar_espacio_no_asignado ;;
        4) listar_particiones_expansibles ;;
        5) expandir_particion ;;
        6) continue ;;
        7) echo -e "\e[1;31mSaliendo del script. ¡Hasta luego!\e[0m"; exit ;;
        *) echo -e "\e[1;31mOpción no válida. Intente de nuevo.\e[0m" ;;
    esac
done

