Script de ejecución inicial de configuración Sistema Operativo RHEL
Menú de configuración
1. Configurar red
2. Configurar hostname
3. Configurar DNS
4. Configurar NTP
5. Mostrar puerto SSH
6. Mostrar configuración de Chrony
7. Registrar sistema en Red Hat
8. Actualizar sistema operativo
9. Salir
Selecciona una opción: 9
[root@rhel9 ~]# vi initialConfig.sh
[root@rhel9 ~]# cat initialConfig.sh
#!/bin/bash

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
    systemctl restart chronyd.service
    echo "Configuración de NTP completada."
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."
}

# Función para mostrar el puerto SSH
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
    read -n 1 -s -r -p "Presiona cualquier tecla para volver al menú..."

    # Verificación del resultado del comando
    if [ $? -eq 0 ]; then
        echo "El sistema se registró correctamente en Red Hat."
    else
        echo "Error al intentar registrar el sistema en Red Hat. Por favor, verifique las credenciales."
        read -rp "Ingrese su nombre de usuario de Red Hat: " username
        read -rsp "Ingrese su clave de validación de Red Hat: " password
        echo

        # Intentar registrar nuevamente con las credenciales proporcionadas
        subscription-manager register --username="$username" --password="$password" --auto-attach

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

# Menú principal
while true; do
    clear
    echo "Script de ejecución inicial de configuración Sistema Operativo RHEL"
    echo "Menú de configuración"
    echo "1. Configurar red"
    echo "2. Configurar hostname"
    echo "3. Configurar DNS"
    echo "4. Configurar NTP"
    echo "5. Mostrar puerto SSH"
    echo "6. Mostrar configuración de Chrony"
    echo "7. Registrar sistema en Red Hat"
    echo "8. Actualizar sistema operativo"
    echo "9. Salir"

    read -p "Selecciona una opción: " choice

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
        *) echo "Opción no válida. Inténtalo de nuevo." ;;
    esac
done
