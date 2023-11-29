#!/bin/bash

function limpiar_pantalla() {
        clear
}

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

# Función para listar particiones expandibles
function listar_particiones_expandibles() {
    limpiar_pantalla
    echo -e "Particiones LVM (Logical Volumes y Volume Groups) que pueden expandirse:"

    # Obtener todos los LV y VG disponibles
    local lv_list=($(lvdisplay | awk '/LV Path/ {print $3}'))
    local vg_list=($(vgdisplay | awk '/VG Name/ {print $3}'))

    # Imprimir la lista de LV con el tipo de sistema de archivos y espacio disponible
    if [ ${#lv_list[@]} -gt 0 ]; then
        echo -e "\nLogical Volumes:"
        for lv in "${lv_list[@]}"; do
            fs_type=$(blkid -o value -s TYPE "$lv")
            espacio_disponible=$(df -h --output=avail "$lv" | tail -n 1)
            echo "- $lv (Tipo de Sistema de Archivos: $fs_type, Espacio Disponible: $espacio_disponible)"
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
    # Llamar a la función para obtener los discos nuevos
    nombres_discos_nuevos=($(obtener_discos_nuevos))

    # Mostrar la información adicional sobre los discos físicos nuevos
    mostrar_informacion_adicional "${nombres_discos_nuevos[@]}"

    # Obtener la lista de discos físicos sin particiones LVM
    discos_disponibles=($(lsblk -o NAME,TYPE | awk '$2 == "disk" {print $1}'))

    # Filtrar discos que no están en la lista de discos nuevos
    discos_disponibles=($(comm -23 <(printf "%s\n" "${discos_disponibles[@]}" | sort) <(printf "%s\n" "${nombres_discos_nuevos[@]}" | sort)))

    if [ ${#discos_disponibles[@]} -eq 0 ]; then
        echo "No hay discos físicos disponibles sin particiones LVM."

        # Permitir al usuario generar un nuevo VG o asignar un disco físico a un VG existente
        read -p "¿Desea generar un nuevo Volume Group (VG) o asignar un disco físico a un VG existente? (s/n): " respuesta

        if [ "$respuesta" = "s" ]; then
            # Seleccionar o crear un Volume Group (VG)
            PS3="Seleccione el número del disco para crear o seleccionar un Volume Group (VG): "
            select disco in "${discos_disponibles[@]}"; do
                if [ -n "$disco" ]; then
                    read -p "Ingrese el nombre del nuevo o existente Volume Group (VG): " nombre_vg

                    # Verificar si el VG ya existe
                    if vgdisplay $nombre_vg &> /dev/null; then
                        echo "Seleccionando el Volume Group (VG) existente: $nombre_vg"
                    else
                        # Crear un nuevo VG
                        vgcreate $nombre_vg $disco
                        echo "Creando el nuevo Volume Group (VG): $nombre_vg en el disco $disco"
                    fi

                    # Solicitar al usuario que seleccione el LV
                    PS3="Seleccione el número del Logical Volume (LV) que desea expandir: "
                    select lv in "${lv_list[@]}"; do
                        if [ -n "$lv" ]; then
                            # Solicitar la cantidad de espacio adicional en MB
                            read -p "Ingrese la cantidad de espacio adicional en megabytes para $lv: " espacio_mb

                            # Extender el LV y su filesystem
                            lvextend -L +${espacio_mb}M /dev/$nombre_vg/$lv
                            resize2fs /dev/$nombre_vg/$lv
                            echo -e "\nEl Logical Volume (LV) $lv en el Volume Group (VG) $nombre_vg se ha expandido en $espacio_mb megabytes en el disco $disco."
                            break
                        else
                            echo "Opción no válida. Intente de nuevo."
                        fi
                    done
                else
                    echo "Opción no válida. Intente de nuevo."
                fi
            done
        fi

        return
    fi
}

crear_particion_lvm() {
    # Crear una partición LVM en el disco seleccionado
    echo "Creando una partición LVM en el disco seleccionado..."
    read -p "Ingrese el nombre del disco para crear una partición LVM: " disco

    # Mostrar los PV actuales
    echo -e "\nPhysical Volumes (PV) actuales:"
    pvs

    read -p "¿Desea asignar la partición a un PV existente o crear uno nuevo? (existente/nuevo): " eleccion

    if [ "$eleccion" == "existente" ]; then
        read -p "Ingrese el nombre del PV existente al que desea asignar la partición: " pv_existente

        # Utilizar fdisk para crear una partición
        fdisk /dev/$disco

        # Agregar la partición al PV existente
        pvcreate /dev/${disco}1
        vgextend $pv_existente /dev/${disco}1
        echo "La partición se ha asignado al PV existente: $pv_existente"
    elif [ "$eleccion" == "nuevo" ]; then
        read -p "Ingrese el nombre del nuevo PV que se creará: " nuevo_pv

        # Utilizar fdisk para crear una partición
        fdisk /dev/$disco

        # Crear un nuevo PV y VG
        pvcreate /dev/${disco}1
        vgcreate $nuevo_pv /dev/${disco}1
        echo "Se ha creado un nuevo PV y VG: $nuevo_pv"
    else
        echo "Opción no válida. Volviendo al menú principal."
    fi
}

crear_vg_lv() {
    # Crear un nuevo Volume Group (VG) y Logical Volume (LV)
    echo "Creando un nuevo Volume Group (VG) y Logical Volume (LV)..."
    read -p "Ingrese el nombre del nuevo Volume Group (VG): " nombre_vg
    read -p "Ingrese el nombre del nuevo Logical Volume (LV): " nombre_lv
    read -p "Ingrese el tamaño inicial del Logical Volume (LV) en megabytes: " tamano_inicial_mb

    # Crear el nuevo VG y LV
    vgcreate $nombre_vg /dev/${disco}1
    lvcreate -L ${tamano_inicial_mb}M -n $nombre_lv $nombre_vg
}

rollback() {
    limpiar_pantalla
    echo "Realizando rollback..."

    # Mostrar discos físicos asignados
    echo "Discos físicos asignados:"
    pvs -o +devices

    read -p "Ingrese el nombre del disco físico que desea deshacer (por ejemplo, /dev/sdX): " disco_rollback

    # Verificar si el disco especificado es /dev/sda
    if [ "$disco_rollback" == "/dev/sda" ]; then
        echo "Error: No se puede realizar un rollback sobre el disco principal del sistema (/dev/sda). Operación cancelada."
        return
    fi

    # Verificar si el disco pertenece a LVM
    if ! pvs $disco_rollback &> /dev/null; then
        echo "Error: El disco especificado no pertenece a un Physical Volume (PV) de LVM. Operación cancelada."
        return
    fi

    # Confirmación del usuario
    read -p "¿Está seguro de que desea deshacer la asignación del disco físico $disco_rollback? (s/n): " confirmacion
    if [ "$confirmacion" != "s" ]; then
        echo "Operación cancelada por el usuario."
        return
    fi

    # Desasignar el disco físico del PV, VG y LV
    echo "Ejecutando: pvremove $disco_rollback"
    pvremove $disco_rollback

    echo "Ejecutando: vgremove $(vgdisplay $disco_rollback | awk '/VG Name/ {print $3}')"
    vgremove $(vgdisplay $disco_rollback | awk '/VG Name/ {print $3}')

    echo "Ejecutando: lvremove $(lvdisplay $disco_rollback | awk '/LV Path/ {print $3}')"
    lvremove $(lvdisplay $disco_rollback | awk '/LV Path/ {print $3}')

    echo "Rollback completado. El disco físico $disco_rollback ha sido desasignado."

    # Actualizar la información de discos
    mostrar_escanear_discos_vmware
}

# Bucle principal
while true; do
    limpiar_pantalla
    echo -e "--- Menú Principal ---"
    echo "1. Refrescar y detectar discos"
    echo "2. Listar FS LVM que pueden expandirse"
    echo "3. Crear nueva partición LVM (solo nuevos FS)"
    echo "4. Expandir partición existente"
    echo "5. Crear nuevo Volume Group (VG) y Logical Volume (LV)"
    echo "6. Rollback (Deshacer asignación de disco físico)"
    echo "7. Salir"

    read -p "Seleccione una opción (1-7): " opcion

    case $opcion in
        1) nombres_discos_nuevos=($(obtener_discos_nuevos))
mostrar_informacion_adicional "${nombres_discos_nuevos[@]}" ;;
        2) listar_particiones_expandibles ;;
        3) crear_particion_lvm ;;
        4) expandir_particion ;;
        5) crear_vg_lv ;;
        6) rollback ;;
        7) echo "Saliendo del script. ¡Hasta luego!"; exit ;;
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac

    read -p "Presione Enter para volver al menú anterior..."
done
