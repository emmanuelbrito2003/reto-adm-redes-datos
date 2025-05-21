#!/bin/bash

# Script SSH Universidad - Version Final Consolidada
# Administracion completa de dispositivos de red internos
# Incluye: SSH, Diagnostico SNMP, Preparacion Python/REST

# Colores para mejor visualizacion
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Variables globales
DEVICES_FILE="/root/.network_devices"
LOG_FILE="/var/log/network_admin.log"

# Funcion para logging
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Funcion para crear configuracion SSH temporal
create_ssh_config() {
    local config_file="/tmp/ssh_config_cisco"
    cat > "$config_file" << EOF
Host *
    KexAlgorithms +diffie-hellman-group1-sha1,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
    Ciphers +aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr
    HostKeyAlgorithms +ssh-rsa,ssh-dss
    PubkeyAcceptedKeyTypes +ssh-rsa,ssh-dss
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
    ConnectTimeout 15
    ServerAliveInterval 30
    ServerAliveCountMax 3
EOF
    echo "$config_file"
}

# Funcion para conectar con configuracion SSH especifica para Cisco
connect_device() {
    local ip=$1
    local name=$2
    
    log_action "Conectando a $name ($ip)"
    echo -e "${GREEN}Conectando a $name ($ip)...${NC}"
    
    # Verificar conectividad antes de intentar SSH
    echo -e "${YELLOW}Verificando conectividad...${NC}"
    if ! ping -c 1 -W 3 $ip >/dev/null 2>&1; then
        echo -e "${RED}? Error: $ip no responde a ping${NC}"
        log_action "ERROR: $name ($ip) no responde a ping"
        echo -e "${YELLOW}Presiona Enter para continuar...${NC}"
        read
        return 1
    fi
    
    echo -e "${GREEN}? Dispositivo responde a ping${NC}"
    
    # Crear configuracion SSH temporal
    local ssh_config=$(create_ssh_config)
    
    echo -e "${YELLOW}Estableciendo conexion SSH...${NC}"
    echo -e "${CYAN}Tip: Usuario 'admin', Password 'cisco'${NC}"
    echo -e "${CYAN}Presiona Ctrl+D o escribe 'exit' para volver al menu${NC}"
    echo
    
    # Intentar conexion SSH con configuracion especifica
    ssh -F "$ssh_config" admin@$ip
    
    # Limpiar archivo temporal
    rm -f "$ssh_config"
    
    log_action "Sesion SSH terminada con $name ($ip)"
    echo
    echo -e "${YELLOW}Conexion terminada. Presiona Enter para continuar...${NC}"
    read
}

# Funcion para detectar el entorno de ejecucion
detect_environment() {
    echo -e "${YELLOW}Detectando entorno de ejecucion...${NC}"
    
    # Verificar si es EVE-NG host
    if [[ -f /opt/unetlab/VERSION ]] || command -v eve-ng-version &> /dev/null; then
        echo -e "${GREEN}? Detectado: Servidor EVE-NG Host${NC}"
        return 0
    fi
    
    # Verificar si tiene la configuracion de red de la topologia
    if ip addr show eth0 2>/dev/null | grep -q "64.100.1"; then
        echo -e "${GREEN}? Detectado: Servidor Linux en Topologia Universidad${NC}"
        echo -e "${BLUE}  - eth0: $(ip addr show eth0 | grep 'inet ' | awk '{print $2}')${NC}"
        echo -e "${BLUE}  - eth1: $(ip addr show eth1 | grep 'inet ' | awk '{print $2}')${NC}"
        return 1
    fi
    
    # Detectar cualquier servidor Linux con conectividad a la red
    echo -e "${GREEN}? Detectado: Servidor Linux Generico${NC}"
    echo -e "${BLUE}Interfaces de red detectadas:${NC}"
    ip addr show | grep -E "inet.*eth|inet.*ens" | awk '{print "  - "$NF": "$2}'
    return 2
}

# Funcion para mostrar el menu principal
show_menu() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}     ADMINISTRACION RED UNIVERSIDAD${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo
    echo -e "${PURPLE}ROUTERS:${NC}"
    echo -e "  ${BLUE}1)${NC} R1 (Core)           - 192.168.1.241"
    echo -e "  ${BLUE}2)${NC} R2 (NAT/Gateway)    - 192.168.0.1"
    echo -e "  ${BLUE}3)${NC} R3 (Router-on-Stick) - 192.168.1.246"
    echo
    echo -e "${PURPLE}SWITCHES:${NC}"
    echo -e "  ${BLUE}4)${NC} Switch9 (VLAN 1,2)  - 192.168.0.2"
    echo -e "  ${BLUE}5)${NC} Switch8 (Red 0.128) - 192.168.0.130"
    echo -e "  ${BLUE}6)${NC} Switch7 (Core VLAN) - 172.16.0.2"
    echo -e "  ${BLUE}7)${NC} Switch6 (Access)    - 172.16.0.3"
    echo -e "  ${BLUE}8)${NC} Switch5 (Access)    - 172.16.0.4"
    echo
    echo -e "${PURPLE}HERRAMIENTAS:${NC}"
    echo -e "  ${BLUE}9)${NC} Estado de la Red (ping test)"
    echo -e "  ${BLUE}10)${NC} Diagnostico SNMP Completo"
    echo -e "  ${BLUE}11)${NC} Informacion del Sistema"
    echo -e "  ${BLUE}12)${NC} Test de Conectividad Avanzado"
    echo -e "  ${BLUE}13)${NC} Comandos SSH Manuales"
    echo -e "  ${BLUE}14)${NC} Ver logs de administracion"
    echo -e "  ${BLUE}0)${NC} Salir"
    echo
    echo -e "${CYAN}================================================${NC}"
}

# Funcion para ping test basico
ping_test() {
    echo -e "${YELLOW}Probando conectividad a todos los dispositivos...${NC}"
    echo
    
    # Solo dispositivos internos de la universidad
    devices=(
        "192.168.1.241:R1"
        "192.168.0.1:R2"
        "192.168.1.246:R3"
        "192.168.0.2:Switch9"
        "192.168.0.130:Switch8"
        "172.16.0.2:Switch7"
        "172.16.0.3:Switch6"
        "172.16.0.4:Switch5"
    )
    
    log_action "Ejecutando ping test a dispositivos"
    echo -e "${CYAN}Resultado de conectividad:${NC}"
    
    online_count=0
    total_devices=${#devices[@]}
    
    for device in "${devices[@]}"; do
        IFS=':' read -ra ADDR <<< "$device"
        ip=${ADDR[0]}
        name=${ADDR[1]}
        
        printf "%-45s" "  $name ($ip)"
        if ping -c 1 -W 2 $ip >/dev/null 2>&1; then
            echo -e "${GREEN}ONLINE${NC}"
            ((online_count++))
        else
            echo -e "${RED}OFFLINE${NC}"
            log_action "ALERTA: $name ($ip) no responde a ping"
        fi
    done
    
    echo
    echo -e "${BLUE}Resumen: $online_count/$total_devices dispositivos online${NC}"
    log_action "Ping test completado: $online_count/$total_devices online"
    echo
    read -p "Presiona Enter para continuar..."
}

# Funcion de diagnostico SNMP completo
diagnose_snmp_complete() {
    clear
    echo -e "${CYAN}=== DIAGNOSTICO SNMP COMPLETO ===${NC}"
    echo -e "${BLUE}Verificando SNMP en dispositivos de la Universidad${NC}"
    echo
    
    log_action "Iniciando diagnostico SNMP completo"
    
    # 1. Verificar instalacion SNMP
    echo -e "${YELLOW}1. Verificando herramientas SNMP...${NC}"
    if ! command -v snmpwalk >/dev/null 2>&1; then
        echo -e "${RED}? SNMP no instalado${NC}"
        echo -e "${YELLOW}Instalando herramientas SNMP...${NC}"
        
        if command -v yum >/dev/null 2>&1; then
            sudo yum install -y net-snmp-utils >/dev/null 2>&1
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update >/dev/null 2>&1
            sudo apt install -y snmp snmp-mibs-downloader >/dev/null 2>&1
        fi
        
        if command -v snmpwalk >/dev/null 2>&1; then
            echo -e "${GREEN}? SNMP instalado exitosamente${NC}"
        else
            echo -e "${RED}? Error instalando SNMP${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}? SNMP ya instalado${NC}"
    fi
    
    # 2. Configurar MIBs
    echo -e "${YELLOW}2. Configurando MIBs...${NC}"
    sudo mkdir -p /etc/snmp
    if ! grep -q "mibs +ALL" /etc/snmp/snmp.conf 2>/dev/null; then
        echo "mibs +ALL" | sudo tee -a /etc/snmp/snmp.conf >/dev/null
        echo -e "${GREEN}? MIBs configurados${NC}"
    else
        echo -e "${GREEN}? MIBs ya configurados${NC}"
    fi
    
    # 3. Test SNMP a dispositivos Universidad
    echo -e "${YELLOW}3. Probando SNMP en dispositivos...${NC}"
    
    devices=(
        "192.168.1.241:R1:public"
        "192.168.0.1:R2:public"
        "192.168.1.246:R3:public"
        "172.16.0.2:Switch7:public"
        "172.16.0.3:Switch6:public"
        "172.16.0.4:Switch5:public"
        "192.168.0.2:Switch9:public"
        "192.168.0.130:Switch8:public"
    )
    
    snmp_working=0
    total_devices=${#devices[@]}
    
    for device in "${devices[@]}"; do
        IFS=':' read -ra DEV <<< "$device"
        ip=${DEV[0]}
        name=${DEV[1]}
        community=${DEV[2]}
        
        printf "%-30s" "  $name ($ip)"
        
        # Test SNMP con timeout optimizado
        if timeout 3 snmpget -v2c -c $community -r 1 -t 2 $ip 1.3.6.1.2.1.1.3.0 2>/dev/null | grep -q "Timeticks"; then
            echo -e "${GREEN}SNMP OK${NC}"
            ((snmp_working++))
        else
            echo -e "${RED}NO RESPONDE${NC}"
            log_action "ALERTA: $name ($ip) no responde SNMP"
        fi
    done
    
    echo
    echo -e "${CYAN}=== RESUMEN DIAGNOSTICO ===${NC}"
    echo -e "${BLUE}Dispositivos SNMP funcionando: ${GREEN}$snmp_working/$total_devices${NC}"
    
    if [ $snmp_working -ge 6 ]; then
        echo -e "${GREEN}? SNMP funcionando correctamente en la mayoria de dispositivos${NC}"
        echo -e "${BLUE}? Red lista para monitoreo en Zabbix${NC}"
        log_action "Diagnostico SNMP exitoso: $snmp_working/$total_devices funcionando"
    else
        echo -e "${YELLOW}? Algunos dispositivos no responden SNMP${NC}"
        echo -e "${BLUE}Verificar configuraciones individuales${NC}"
        log_action "Diagnostico SNMP con advertencias: $snmp_working/$total_devices funcionando"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

# Funcion para mostrar informacion del sistema
show_system_info() {
    clear
    echo -e "${CYAN}=== INFORMACION DEL SISTEMA ===${NC}"
    echo
    
    echo -e "${YELLOW}Sistema:${NC}"
    echo -e "  Hostname: $(hostname)"
    echo -e "  Usuario: $(whoami)"
    echo -e "  Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo -e "  Directorio: $(pwd)"
    echo
    
    echo -e "${YELLOW}Red:${NC}"
    echo -e "  Interfaces principales:"
    ip addr show | grep -E "^[0-9]|inet " | grep -E "eth|ens" | sed 's/^/    /'
    echo
    
    echo -e "${YELLOW}Rutas importantes:${NC}"
    ip route | grep -E "default|192\.168|172\.16|64\.100" | sed 's/^/    /'
    echo
    
    echo -e "${YELLOW}Servicios de red:${NC}"
    echo -e "  DNS: $(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}')"
    echo -e "  SSH: $(ssh -V 2>&1 | head -1)"
    
    if command -v snmpwalk >/dev/null 2>&1; then
        echo -e "  SNMP: ? Instalado ($(snmpwalk -V 2>&1 | head -1))"
    else
        echo -e "  SNMP: ? No instalado"
    fi
    echo
    
    echo -e "${YELLOW}Logs recientes:${NC}"
    if [ -f "$LOG_FILE" ]; then
        echo -e "  Ultimas 5 acciones:"
        tail -5 "$LOG_FILE" | sed 's/^/    /'
    else
        echo -e "  Sin logs de administracion"
    fi
    echo
    
    read -p "Presiona Enter para continuar..."
}

# Funcion para test de conectividad avanzado
advanced_connectivity_test() {
    clear
    echo -e "${CYAN}=== TEST DE CONECTIVIDAD AVANZADO ===${NC}"
    echo
    
    log_action "Ejecutando test de conectividad avanzado"
    
    # Test de rutas hacia diferentes redes INTERNAS
    networks=(
        "192.168.0.1:Red VLAN1"
        "192.168.0.129:Red Switch8"
        "192.168.1.1:VLAN10 VENTAS"
        "192.168.1.65:VLAN20 MARK"
        "192.168.1.129:VLAN30 RRHH"
        "172.16.0.1:VLAN50 ADMINS"
        "64.100.1.1:Gateway Servidor"
    )
    
    echo -e "${YELLOW}Verificando conectividad hacia gateways:${NC}"
    for network in "${networks[@]}"; do
        IFS=':' read -ra NET <<< "$network"
        ip=${NET[0]}
        desc=${NET[1]}
        
        printf "%-50s" "  $desc ($ip)"
        if ping -c 1 -W 1 $ip >/dev/null 2>&1; then
            echo -e "${GREEN}ALCANZABLE${NC}"
        else
            echo -e "${RED}NO ALCANZABLE${NC}"
        fi
    done
    echo
    
    # Test de servicios SSH en dispositivos principales
    echo -e "${YELLOW}Verificando servicios SSH:${NC}"
    ssh_devices=(
        "192.168.1.241:R1"
        "192.168.0.1:R2"
        "192.168.1.246:R3"
        "172.16.0.2:Switch7"
    )
    
    for device in "${ssh_devices[@]}"; do
        IFS=':' read -ra DEV <<< "$device"
        ip=${DEV[0]}
        name=${DEV[1]}
        
        printf "%-40s" "  SSH $name ($ip)"
        if nc -z -w3 $ip 22 2>/dev/null; then
            echo -e "${GREEN}PUERTO 22 ABIERTO${NC}"
        else
            echo -e "${RED}PUERTO 22 CERRADO${NC}"
        fi
    done
    echo
    
    # Test SNMP rapido si esta disponible
    if command -v snmpwalk >/dev/null 2>&1; then
        echo -e "${YELLOW}Verificando servicios SNMP (muestra):${NC}"
        snmp_devices=(
            "192.168.1.241:R1"
            "172.16.0.2:Switch7"
            "192.168.0.1:R2"
        )
        
        for device in "${snmp_devices[@]}"; do
            IFS=':' read -ra DEV <<< "$device"
            ip=${DEV[0]}
            name=${DEV[1]}
            
            printf "%-40s" "  SNMP $name ($ip)"
            if timeout 2 snmpget -v2c -c public $ip 1.3.6.1.2.1.1.3.0 2>/dev/null | grep -q "Timeticks"; then
                echo -e "${GREEN}RESPONDIENDO${NC}"
            else
                echo -e "${RED}SIN RESPUESTA${NC}"
            fi
        done
        echo
    fi
    
    # Test de DNS
    echo -e "${YELLOW}Verificando resolucion DNS:${NC}"
    dns_tests=("google.com" "cloudflare.com")
    
    for domain in "${dns_tests[@]}"; do
        printf "%-30s" "  $domain"
        if nslookup $domain >/dev/null 2>&1; then
            echo -e "${GREEN}RESOLVIBLE${NC}"
        else
            echo -e "${RED}NO RESOLVIBLE${NC}"
        fi
    done
    echo
    
    log_action "Test de conectividad avanzado completado"
    read -p "Presiona Enter para continuar..."
}

# Funcion para mostrar comandos SSH manuales
show_ssh_commands() {
    clear
    echo -e "${CYAN}=== COMANDOS SSH MANUALES ===${NC}"
    echo
    echo -e "${YELLOW}Para conectar manualmente a los dispositivos, usa estos comandos:${NC}"
    echo
    
    devices=(
        "192.168.1.241:R1 (Core)"
        "192.168.0.1:R2 (NAT/Gateway)"
        "192.168.1.246:R3 (Router-on-Stick)"
        "192.168.0.2:Switch9 (VLAN 1,2)"
        "192.168.0.130:Switch8 (Red 0.128)"
        "172.16.0.2:Switch7 (Core VLAN)"
        "172.16.0.3:Switch6 (Access)"
        "172.16.0.4:Switch5 (Access)"
    )
    
    echo -e "${BLUE}Comando SSH optimizado para dispositivos Cisco:${NC}"
    echo
    
    for device in "${devices[@]}"; do
        IFS=':' read -ra DEV <<< "$device"
        ip=${DEV[0]}
        name=${DEV[1]}
        
        echo -e "${GREEN}# $name${NC}"
        echo -e "${CYAN}ssh -o KexAlgorithms=+diffie-hellman-group1-sha1 -o Ciphers=+aes128-cbc admin@$ip${NC}"
        echo
    done
    
    echo -e "${YELLOW}Credenciales:${NC}"
    echo -e "  Usuario: ${GREEN}admin${NC}"
    echo -e "  Contrasena: ${GREEN}cisco${NC}"
    echo
    
    echo -e "${YELLOW}Script SSH configurado automaticamente para compatibilidad legacy${NC}"
    echo
    
    read -p "Presiona Enter para continuar..."
}


# Funcion para ver logs de administracion
show_admin_logs() {
    clear
    echo -e "${CYAN}=== LOGS DE ADMINISTRACION ===${NC}"
    echo
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}Ultimas 20 acciones registradas:${NC}"
        echo
        tail -20 "$LOG_FILE" | while read line; do
            # Colorear segun tipo de accion
            if [[ "$line" == *"ERROR"* ]] || [[ "$line" == *"ALERTA"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ "$line" == *"Conectando"* ]] || [[ "$line" == *"exitoso"* ]]; then
                echo -e "${GREEN}$line${NC}"
            else
                echo -e "${BLUE}$line${NC}"
            fi
        done
        echo
        echo -e "${BLUE}Archivo completo: $LOG_FILE${NC}"
    else
        echo -e "${YELLOW}No hay logs de administracion disponibles${NC}"
        echo -e "${BLUE}Los logs se generaran automaticamente con el uso del script${NC}"
    fi
    echo
    
    read -p "Presiona Enter para continuar..."
}

# Funcion principal
main() {
    # Crear archivo de log si no existe
    sudo touch "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
    
    # Detectar entorno al inicio
    detect_environment
    ENV_TYPE=$?
    echo
    
    # Mostrar informacion adicional segun el entorno
    case $ENV_TYPE in
        0)
            echo -e "${BLUE}Modo: EVE-NG Host - Acceso completo a la topologia${NC}"
            ;;
        1)
            echo -e "${BLUE}Modo: Servidor en Topologia - Acceso desde red interna${NC}"
            ;;
        2)
            echo -e "${BLUE}Modo: Servidor Generico - Verificando conectividad...${NC}"
            ;;
    esac
    echo
    
    log_action "Script de administracion iniciado - Modo $ENV_TYPE"
    read -p "Presiona Enter para continuar..."
    
    while true; do
        show_menu
        read -p "Selecciona una opcion (0-15): " choice
        
        case $choice in
            1) connect_device "192.168.1.241" "R1 (Core Router)" ;;
            2) connect_device "192.168.0.1" "R2 (NAT/Gateway)" ;;
            3) connect_device "192.168.1.246" "R3 (Router-on-Stick)" ;;
            4) connect_device "192.168.0.2" "Switch9 (VLAN 1,2)" ;;
            5) connect_device "192.168.0.130" "Switch8 (Red 0.128)" ;;
            6) connect_device "172.16.0.2" "Switch7 (Core VLAN)" ;;
            7) connect_device "172.16.0.3" "Switch6 (Access)" ;;
            8) connect_device "172.16.0.4" "Switch5 (Access)" ;;
            9) ping_test ;;
            10) diagnose_snmp_complete ;;
            11) show_system_info ;;
            12) advanced_connectivity_test ;;
            13) show_ssh_commands ;;
            14) show_admin_logs ;;
            0) 
                echo -e "${GREEN}¡Hasta luego!${NC}"
                log_action "Script de administracion finalizado"
                exit 0
                ;;
            *)
                echo -e "${RED}Opcion invalida. Presiona Enter para continuar...${NC}"
                read
                ;;
        esac
    done
}

# Verificar y crear configuracion SSH global si es necesario
setup_ssh_client() {
    local ssh_dir="$HOME/.ssh"
    local ssh_config="$ssh_dir/config"
    
    # Crear directorio .ssh si no existe
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    # Verificar si ya existe configuracion para Cisco
    if ! grep -q "# Cisco devices configuration" "$ssh_config" 2>/dev/null; then
        echo -e "${YELLOW}Configurando cliente SSH para dispositivos Cisco...${NC}"
        
        # Hacer backup de configuracion existente
        if [ -f "$ssh_config" ]; then
            cp "$ssh_config" "$ssh_config.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Agregar configuracion para dispositivos Cisco
        cat >> "$ssh_config" << 'EOF'

# Cisco devices configuration - Universidad
Host 192.168.*
    KexAlgorithms +diffie-hellman-group1-sha1,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
    Ciphers +aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc
    HostKeyAlgorithms +ssh-rsa,ssh-dss
    PubkeyAcceptedKeyTypes +ssh-rsa,ssh-dss
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host 172.16.*
    KexAlgorithms +diffie-hellman-group1-sha1,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
    Ciphers +aes128-cbc,3des-cbc,aes192-cbc,aes256-cbc
    HostKeyAlgorithms +ssh-rsa,ssh-dss
    PubkeyAcceptedKeyTypes +ssh-rsa,ssh-dss
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
        
        chmod 600 "$ssh_config"
        echo -e "${GREEN}? Configuracion SSH actualizada${NC}"
    fi
}

# Ejecutar configuracion inicial y lanzar script
setup_ssh_client
echo
main