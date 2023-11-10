#!/bin/bash

# Función para configurar la red
configure_network() {
    echo "Configuración de red"
    read -p "Introduce la dirección IP: " ip_address
    read -p "Introduce la máscara de red: " netmask
    read -p "Introduce la puerta de enlace (gateway): " gateway

    # Configuración de la interfaz de red
    nmcli connection modify ens192 ipv4.address $ip_address/$netmask ipv4.gateway $gateway
    nmcli connection up ens192
    echo "Configuración de red completada."
}

# Función para configurar el hostname
configure_hostname() {
    echo "Configuración del hostname"
    read -p "Introduce el nuevo hostname: " new_hostname

    hostnamectl set-hostname $new_hostname
    echo "Hostname configurado correctamente."
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
}

# Función para mostrar el puerto SSH
show_ssh_port() {
    ssh_port=$(ss -tlnp | grep ssh | awk '{print $4}' | cut -d ':' -f 2)
    echo "El puerto activo para SSH es: $ssh_port"
}

# Función para configurar el origen horario (NTP)
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

    echo "Configuración de NTP completada."
}

# Función para registrar el sistema en Red Hat
register_redhat_system() {
    subscription-manager register
}

# Función para actualizar el sistema operativo
update_system() {
    yum update -y
}

# Menú principal
while true; do
    clear
    echo "Script de ejecución inicial de configuración Sistema Operativo RHEL"
    echo "Menú de configuración"
    echo "1. Configurar red"
    echo "2. Configurar hostname"
    echo "3. Configurar DNS"
    echo "4. Mostrar puerto SSH"
    echo "5. Mostrar configuración de Chrony"
    echo "6. Registrar sistema en Red Hat"
    echo "7. Actualizar sistema operativo"
    echo "8. Salir"

    read -p "Selecciona una opción: " choice

    case $choice in
        1) configure_network ;;
        2) configure_hostname ;;
        3) configure_dns ;;
        4) show_ssh_port ;;
        5) show_chrony_config ;;
        6) register_redhat_system ;;
        7) update_system ;;
        8) exit ;;
        *) echo "Opción no válida. Inténtalo de nuevo." ;;
    esac
done
