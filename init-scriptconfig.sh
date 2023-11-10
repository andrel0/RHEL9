#!/bin/bash

# Función para configurar la red
configure_network() {
    echo "Configuración de red"
    read -p "Introduce la dirección IP: " ip_address
    read -p "Introduce la máscara de red: " netmask
    read -p "Introduce la puerta de enlace (gateway): " gateway

    # Configuración de la interfaz de red
    cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
IPADDR=$ip_address
NETMASK=$netmask
GATEWAY=$gateway
EOF

    systemctl restart network
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
    read -p "Introduce la dirección del servidor DNS: " dns_server

    # Configuración del archivo resolv.conf
    echo "nameserver $dns_server" > /etc/resolv.conf
    echo "DNS configurado correctamente."
}

# Función para mostrar el puerto SSH
show_ssh_port() {
    ssh_port=$(ss -tlnp | grep ssh | awk '{print $4}' | cut -d ':' -f 2)
    echo "El puerto activo para SSH es: $ssh_port"
}

# Función para mostrar la configuración de Chrony
show_chrony_config() {
    echo "Configuración de Chrony"
    cat /etc/chrony.conf
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
