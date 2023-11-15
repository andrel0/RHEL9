#!/bin/bash

# Definir colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para configurar la red
configure_network() {
    echo "Configuración de red"
    read -p "Introduce la dirección IP: " ip_address
    read -p "Introduce la máscara de red (indicando prefijo ejemplo /24): " netmask
    read -p "Introduce la puerta de enlace (gateway): " gateway

    nmcli connection modify ens192 ipv4.address $ip_address$netmask ipv4.gateway $gateway
    nmcli connection up ens192

    nmcli connection down ens192
    nmcli connection up ens192

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

    echo "nameserver $dns_server1" > /etc/resolv.conf
    echo "nameserver $dns_server2" >> /etc/resolv.conf

    nmcli connection modify ens192 ipv4.dns "$dns_server1 $dns_server2"
    nmcli connection up ens192

    echo -e "${YELLOW}DNS configurado correctamente:${NC}"
    grep -v '^#\|^$' /etc/resolv.conf
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para configurar zona horaria (NTP)
configure_ntp() {
    echo "Configuración de NTP"
    read -p "¿Cuántos servidores NTP deseas registrar? " num_ntp_servers

    if [[ ! $num_ntp_servers =~ ^[1-9][0-9]*$ ]]; then
        echo "Número de servidores NTP no válido. Debe ser un número entero mayor que cero."
        return
    fi

    sed -i '/pool /d' /etc/chrony.conf

    for ((i=1; i<=$num_ntp_servers; i++)); do
        read -p "Introduce la dirección IP del servidor NTP $i: " ntp_ip
        echo "pool $ntp_ip iburst" >> /etc/chrony.conf
    done

    systemctl restart chronyd.service

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

# Función para mostrar la configuración de Chrony - Date - timedatectl
show_chrony_config() {
    echo -e "${YELLOW}Fecha / Hora:${NC}"
    timedatectl
    echo -e "${YELLOW}Status del Servicio chronyd:${NC}"
    systemctl is-enabled chronyd
    systemctl is-active chronyd
    echo -e "${YELLOW}Configuración actual Chrony:${NC}"
    grep -v '^#\|^$' /etc/chrony.conf
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar el status de firewalld y reglas creadas
show_firewalld_status() {
    echo -e "${YELLOW}Mostrando status de  servicio firewalld:${NC}"
    systemctl is-active firewalld
    systemctl is-enabled firewalld
    echo -e "${YELLOW}Mostrando reglas de firewalld:${NC}"
    firewall-cmd --list-all
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar configuración de logs y logrotate
show_logs_config() {
    echo -e "${YELLOW}Mostrando status del servicio Rsyslog:${NC}"
    systemctl is-enabled rsyslog
    systemctl is-active rsyslog
    echo -e "${YELLOW}Mostrando configuración actual de logs:${NC}"
    grep -v '^#\|^$' /etc/rsyslog.conf
    echo -e "${YELLOW}Mostrando configuración de logrotate:${NC}"
    grep -v '^#\|^$' /etc/logrotate.conf
    grep -v '^#\|^$' /etc/logrotate.d/*
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar configuración de auditd
show_auditd_config() {
    echo -e "${YELLOW}Mostrando status servicio Auditd:${NC}"
    systemctl is-enabled auditd
    systemctl is-active auditd
    echo -e "${YELLOW}Mostrando configuración de auditd:${NC}"
    auditctl -l
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar directivas de seguridad de contraseñas
#show_pwquality_config() {
#    echo -e "${YELLOW}Mostrando directivas de seguridad de contraseñas:${NC}"
#    echo -e "Longitud mínima de la contraseña: $(authconfig --test | grep "password.*minlen" | awk -F'=' '{print $2}')"
#    echo -e "Longitud máxima de la contraseña: $(authconfig --test | grep "password.*maxlen" | awk -F'=' '{print $2}')"
#    echo -e "Número mínimo de letras en la contraseña: $(authconfig --test | grep "password.*minclass" | awk -F'=' '{print $2}')"
#    echo -e "Número mínimo de dígitos en la contraseña: $(authconfig --test | grep "password.*mindigit" | awk -F'=' '{print $2}')"
#    echo -e "Número mínimo de caracteres especiales en la contraseña: $(authconfig --test | grep "password.*minclass.*-special" | awk -F'=' '{print $2}')"
#    echo -e "Días antes de que una contraseña pueda ser cambiada: $(authconfig --test | grep "password.*minclass.*-change-days" | awk -F'=' '{print $2}')"
#    echo -e "Días antes de que una contraseña deba ser cambiada: $(authconfig --test | grep "password.*maxrepeat" | awk -F'=' '{print $2}')"
#    echo -e "Días antes de que una contraseña deba ser cambiada después de que expire: $(authconfig --test | grep "password.*maxclassrepeat" | awk -F'=' '{print $2}')"
#    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
#}

# Función para registrar el sistema en Red Hat
register_redhat_system() {
    echo "Registrando el sistema en Red Hat..."
    subscription-manager register --auto-attach

    if [ $? -eq 0 ]; then
        echo "El sistema se registró correctamente en Red Hat."
    else
        echo "Error al intentar registrar el sistema en Red Hat. Por favor, verifique las credenciales."
        read -rp "Ingrese su nombre de usuario de Red Hat: " username
        read -rsp "Ingrese su clave de validación de Red Hat: " password
        echo

        subscription-manager register --username="$username" --password="$password" --auto-attach --force

        if [ $? -eq 0 ]; then
            echo "El sistema se registró correctamente en Red Hat con las nuevas credenciales."
        else
            echo "Error al intentar registrar el sistema en Red Hat incluso con las nuevas credenciales. Consulte la documentación."
        fi
    fi

    echo "Mostrando información del sistema:"
    subscription-manager list --installed

    read -n 1 -rsp "Presiona cualquier tecla para volver al menú..."
}

# Función para actualizar el sistema operativo con dnf
update_system() {
    echo "Ejecutando la actualización del sistema operativo con dnf..."

    temp_output=$(mktemp /tmp/dnf_update_output.XXXXXX)

    dnf update -y > "$temp_output" 2>&1 &

    dnf_pid=$!

    while kill -0 $dnf_pid 2>/dev/null; do
        echo -n "."
        sleep 5
    done

    wait $dnf_pid
    if [ $? -eq 0 ]; then
        echo -e "\nLa actualización del sistema operativo se completó correctamente."
        echo -e "Paquetes instalados/actualizados:"
        cat "$temp_output"
    else
        echo -e "\nError durante la actualización del sistema operativo. Consulta los logs para obtener más detalles."
    fi

    rm -f "$temp_output"

    read -n 1 -rsp "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar el menú principal
show_menu() {
    clear
    echo -e "-----------------------------------------"
    echo -e "${GREEN}   Script de Configuración RHEL 9${NC}"
    echo -e "-----------------------------------------"
    echo -e "1. ${YELLOW}Configurar Red${NC}"
    echo -e "2. ${YELLOW}Configurar Hostname${NC}"
    echo -e "3. ${YELLOW}Configurar DNS${NC}"
    echo -e "4. ${YELLOW}Configurar NTP${NC}"
    echo -e "5. ${YELLOW}Mostrar puerto SSH${NC}"
    echo -e "6. ${YELLOW}Mostrar configuración de Chrony/Fecha y Hora${NC}"
    echo -e "7. ${YELLOW}Mostrar status de Firewalld${NC}"
    echo -e "8. ${YELLOW}Mostrar configuración de logs/logrotate${NC}"
    echo -e "9. ${YELLOW}Mostrar configuración de Auditd${NC}"
    echo -e "10. ${YELLOW}Registrar sistema en Red Hat${NC}"
    echo -e "11. ${YELLOW}Actualizar sistema operativo${NC}"
    echo -e "12. ${RED}Salir${NC}"
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
        7) show_firewalld_status ;;
        8) show_logs_config ;;
        9) show_auditd_config ;;
        10) register_redhat_system ;;
        11) update_system ;;
        12) exit ;;
        *) echo -e "${RED}Opción no válida. Inténtalo de nuevo.${NC}" ;;
    esac
done
