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
    echo "Listado de discos físicos:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
}

actualizar_discos() {
    echo -e "\nActualizando información de discos..."
    partprobe
    echo "¡Información de discos actualizada!"
}

listar_particiones_expansibles() {
    limpiar_pantalla
    echo -e "Particiones LVM (Logical Volumes y Volume Groups) que pueden expandirse:"

    # Obtener todos los LV y VG disponibles
    lv_list=($(lvdisplay | awk '/LV Path/ {print $3}'))
    vg_list=($(vgdisplay | awk '/VG Name/ {print $3}'))

    # Imprimir la lista de LV
    if [ ${#lv_list[@]} -gt 0 ]; then
        echo -e "\nLogical Volumes:"
        for lv in "${lv_list[@]}"; do
            echo "- $lv"
        done
    fi

    # Imprimir la lista de VG
    if [ ${#vg_list[@]} -gt 0 ]; then
        echo -e "\nVolume Groups:"
        for vg in "${vg_list[@]}"; do
            echo "- $vg"
        done
    fi

    if [ ${#lv_list[@]} -eq 0 ] && [ ${#vg_list[@]} -eq 0 ]; then
        echo "No hay Logical Volumes ni Volume Groups disponibles para expandirse."
    fi
}

expandir_particion() {
    listar_particiones_expansibles

    # Obtener la lista de discos físicos sin LV ni VG asignados
    discos_disponibles=($(lsblk -o NAME,TYPE | awk '$2 == "disk" && system("lvdisplay " $1 " > /dev/null") == 1 && system("vgdisplay " $1 " > /dev/null") == 1 {print $1}'))

    if [ ${#discos_disponibles[@]} -eq 0 ]; then
        echo "No hay discos físicos disponibles para asignar espacio. Todos tienen LV o VG asignados."
        return
    fi

    PS3="Seleccione el número del disco desde el cual desea tomar el espacio disponible: "
    select disco in "${discos_disponibles[@]}"; do
        if [ -n "$disco" ]; then
            read -p "Ingrese la cantidad de espacio adicional en megabytes para $filesystem: " espacio_mb

            lvextend -L +${espacio_mb}M /dev/$filesystem --alloc $disco
            resize2fs /dev/$filesystem
            echo -e "\nEl filesystem $filesystem se ha expandido en $espacio_mb megabytes desde el disco $disco."
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
    echo "3. Listar particiones LVM que pueden expandirse"
    echo "4. Expandir partición LVM"
    echo "5. Salir"

    read -p "Seleccione una opción (1-5): " opcion

    case $opcion in
        1) mostrar_discos ;;
        2) actualizar_discos ;;
        3) listar_particiones_expansibles ;;
        4) expandir_particion ;;
        5) echo "Saliendo del script. ¡Hasta luego!"; exit ;;
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac

    read -p "Presione Enter para volver al menú..."
done
