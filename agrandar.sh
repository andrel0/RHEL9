#!/bin/bash

mostrar_discos_fisicos() {
    echo "Discos físicos disponibles:"
    pvs
}

mostrar_espacio_sin_asignar() {
    echo "Espacio sin asignar en el sistema:"
    pvs --units G --segments
}

expandir_filesystem() {
    echo "Lista de filesystems disponibles:"
    df -h | awk '{if(NR>1)print $NF}'
    read -p "Selecciona el filesystem que deseas expandir: " filesystem

    echo "Espacio disponible para $filesystem:"
    lvdisplay $filesystem | grep "Free  PE" | awk '{print $NF}'

    read -p "¿Quieres expandir al 100% del espacio disponible? (y/n): " option

    if [ "$option" == "y" ]; then
        lvextend -l +100%FREE $filesystem
        resize2fs $filesystem
        echo "Filesystem $filesystem expandido al 100% del espacio disponible."
    else
        echo "Operación cancelada."
    fi
}

mostrar_menu() {
    echo "===== Menú ====="
    echo "1. Mostrar discos físicos"
    echo "2. Mostrar espacio sin asignar"
    echo "3. Expandir tamaño de filesystem"
    echo "4. Salir"
}

while true; do
    mostrar_menu

    read -p "Selecciona una opción (1-4): " opcion

    case $opcion in
        1) mostrar_discos_fisicos ;;
        2) mostrar_espacio_sin_asignar ;;
        3) expandir_filesystem ;;
        4) echo "Saliendo. Adiós."; exit ;;
        *) echo "Opción no válida. Inténtalo de nuevo." ;;
    esac

    echo "Presiona Enter para continuar..."
    read -r
    clear
done
