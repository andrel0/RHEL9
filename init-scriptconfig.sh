#!/bin/bash

# Definir colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# ... (Funciones y código existente)

# Función para configurar la red
configure_network() {
    echo "Configuración de red"
    read -p "Introduce la dirección IP: " ip_address
    read -p "Introduce la máscara de red (indicando prefijo ejemplo /24): " netmask
    read -p "Introduce la puerta de enlace (gateway): " gateway

    # Configuración de la interfaz de red
    nmcli connection modify ens192 ipv4.address $ip_address$netmask ipv4.gateway $gateway
    nmcli connection up ens192

    # Reiniciar la interfaz de red
    nmcli connection down ens192
    nmcli connection up ens192

    # Mostrar información configurada
    echo "Configuración de red completada:"
    echo "Dirección IP: $ip_address"
    echo "Máscara de red: $netmask"
    echo "Puerta de enlace (gateway): $gateway"
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para configurar el hostname
configure_hostname() {
    echo "Configuración del hostname"
    read -p "Introduce el nuevo hostname: " new_hostname

    hostnamectl set-hostname $new_hostname
    echo "Hostname configurado correctamente."
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para configurar el DNS
configure_dns() {
    echo "Configuración de DNS"
    read -p "Introduce el primer servidor DNS: " dns_server1
    read -p "Introduce el segundo servidor DNS: " dns_server2

    # Configuración del archivo resolv.conf
    echo "nameserver $dns_server1" > /etc/resolv.conf
    echo "nameserver $dns_server2" >> /etc/resolv.conf

    # Configuración de la interfaz de red
    nmcli connection modify ens192 ipv4.dns "$dns_server1 $dns_server2"
    nmcli connection up ens192

    echo "DNS configurado correctamente."
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para configurar zona horaria (NTP)
configure_ntp() {
    echo "Configuración de NTP"
    read -p "¿Cuántos servidores NTP deseas registrar? " num_ntp_servers

    # Verificar que el número de servidores NTP sea válido
    if [[ ! $num_ntp_servers =~ ^[1-9][0-9]*$ ]]; then
        echo "Número de servidores NTP no válido. Debe ser un número entero mayor que cero."
        return
    fi

    # Limpiar el archivo chrony.conf de configuraciones anteriores
    sed -i '/pool /d' /etc/chrony.conf

    # Solicitar las direcciones IP de los servidores NTP
    for ((i=1; i<=$num_ntp_servers; i++)); do
        read -p "Introduce la dirección IP del servidor NTP $i: " ntp_ip
        echo "pool $ntp_ip iburst" >> /etc/chrony.conf
    done

    # Reiniciar el servicio Chrony
    systemctl restart chronyd.service

    # Validar el resultado del reinicio
    if [ $? -eq 0 ]; then
        echo "Configuración de NTP completada."
    else
        echo "Error al intentar reiniciar el servicio Chrony. Consulta los logs para obtener más detalles."
    fi

    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar el puerto SSH configurado
show_ssh_port() {
    ssh_port=$(ss -tlnp | grep ssh | awk '{print $4}' | cut -d ':' -f 2)
    echo "El puerto activo para SSH es: $ssh_port"
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar la configuración de Chrony
show_chrony_config() {
    echo "Configuración de Chrony"
    grep -v '^#' /etc/chrony.conf
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para registrar el sistema en Red Hat
register_redhat_system() {
echo "Registrando el sistema en Red Hat..."
    subscription-manager register --auto-attach

    # Verificación del resultado del comando
    if [ $? -eq 0 ]; then
        echo "El sistema se registró correctamente en Red Hat."
    else
        echo "Error al intentar registrar el sistema en Red Hat. Por favor, verifique las credenciales."
        read -rp "Ingrese su nombre de usuario de Red Hat: " username
        read -rsp "Ingrese su clave de validación de Red Hat: " password
        echo

        # Intentar registrar nuevamente con las credenciales proporcionadas
        subscription-manager register --username="$username" --password="$password" --auto-attach --force

        # Verificar el resultado nuevamente
        if [ $? -eq 0 ]; then
            echo "El sistema se registró correctamente en Red Hat con las nuevas credenciales."
        else
            echo "Error al intentar registrar el sistema en Red Hat incluso con las nuevas credenciales. Consulte la documentación."
            # Puedes agregar más acciones aquí según sea necesario.
        fi
    fi

    # Mostrar información del sistema
    echo "Mostrando información del sistema:"
    subscription-manager list --installed

    # Aguardar que el usuario presione una tecla para continuar
    read -n 1 -rsp "Presiona cualquier tecla para volver al menú..."
}

# Función para actualizar el sistema operativo con dnf
update_system() {
    echo "Ejecutando la actualización del sistema operativo con dnf..."

    # Crear un archivo temporal para almacenar la salida
    temp_output=$(mktemp /tmp/dnf_update_output.XXXXXX)

    # Ejecutar la actualización sin intervención del usuario y redirigir la salida y error estándar al archivo temporal
    dnf update -y > "$temp_output" 2>&1 &

    # Obtener el PID del proceso en segundo plano
    dnf_pid=$!

    # Mostrar el progreso
    while kill -0 $dnf_pid 2>/dev/null; do
        echo -n "."
        sleep 5
    done

    # Verificar el código de salida
    wait $dnf_pid
    if [ $? -eq 0 ]; then
        echo -e "\nLa actualización del sistema operativo se completó correctamente."
        echo -e "Paquetes instalados/actualizados:"
        cat "$temp_output"
    else
        echo -e "\nError durante la actualización del sistema operativo. Consulta los logs para obtener más detalles."
    fi

    # Eliminar el archivo temporal
    rm -f "$temp_output"

    read -n 1 -rsp "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar el menú principal
show_menu() {
    clear
    echo -e "-----------------------------------------"
    echo -e "${GREEN}   Script de Configuración RHEL 9${NC}"
    echo -e "-----------------------------------------"
    echo -e "1. ${YELLOW}Configurar red${NC}"
    echo -e "2. ${YELLOW}Configurar hostname${NC}"
    echo -e "3. ${YELLOW}Configurar DNS${NC}"
    echo -e "4. ${YELLOW}Configurar NTP${NC}"
    echo -e "5. ${YELLOW}Mostrar puerto SSH${NC}"
    echo -e "6. ${YELLOW}Mostrar configuración de Chrony${NC}"
    echo -e "7. ${YELLOW}Registrar sistema en Red Hat${NC}"
    echo -e "8. ${YELLOW}Actualizar sistema operativo${NC}"
    echo -e "9. ${RED}Salir${NC}"
    echo -e "-----------------------------------------"
    read -p "Selecciona una opción: " choice
}

# Menú principal
while true; do
    show_menu

    case $choice in
        1) configure_network ;;
        2) configure_hostname ;;
        3) configure_dns ;;
        4) configure_ntp ;;
        5) show_ssh_port ;;
        6) show_chrony_config ;;
        7) register_redhat_system ;;
        8) update_system ;;
        9) exit ;;
        *) echo -e "${RED}Opción no válida. Inténtalo de nuevo.${NC}" ;;
    esac
done
