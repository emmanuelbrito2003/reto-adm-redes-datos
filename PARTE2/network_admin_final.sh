#!/bin/bash

# SCRIPT UNIFICADO PARA ADMINISTRACIÓN UNIVERSIDAD
# Combina todas las funciones esenciales para Syslog + NTP en Zabbix
# Version Final - Mayo 2025

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/var/log/network_admin.log"

# Función de logging
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Función de menú principal
show_main_menu() {
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "${YELLOW}    ADMINISTRACIÓN UNIVERSIDAD - FINAL${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo
    echo -e "${BLUE}1)${NC} Verificar Estado Syslog en Zabbix"
    echo -e "${BLUE}2)${NC} Test UserParameters de todos los dispositivos"
    echo -e "${BLUE}3)${NC} Verificar NTP en dispositivos"
    echo -e "${BLUE}4)${NC} Monitorear logs en tiempo real"
    echo -e "${BLUE}5)${NC} Test de conectividad completo"
    echo -e "${BLUE}6)${NC} Generar logs de prueba"
    echo -e "${BLUE}7)${NC} Mantenimiento de logs"
    echo -e "${BLUE}8)${NC} Configurar NTP/Timezone"
    echo -e "${BLUE}9)${NC} Mostrar configuración Zabbix Items"
    echo -e "${BLUE}0)${NC} Salir"
    echo
    echo -e "${CYAN}================================================${NC}"
}

# Función 1: Verificar estado Syslog
verify_syslog_status() {
    clear
    echo -e "${CYAN}=== VERIFICACIÓN ESTADO SYSLOG ===${NC}"
    
    log_action "Verificando estado Syslog"
    
    # Verificar rsyslog
    echo -e "${YELLOW}1. Estado rsyslog:${NC}"
    if systemctl is-active --quiet rsyslog; then
        echo -e "${GREEN}✓ rsyslog activo${NC}"
    else
        echo -e "${RED}✗ rsyslog inactivo${NC}"
    fi
    
    # Verificar puerto 514
    echo -e "${YELLOW}2. Puerto 514 (syslog):${NC}"
    if ss -ulnp | grep -q ":514"; then
        echo -e "${GREEN}✓ Escuchando en puerto 514${NC}"
    else
        echo -e "${RED}✗ Puerto 514 no disponible${NC}"
    fi
    
    # Verificar archivos de log
    echo -e "${YELLOW}3. Archivos de log activos:${NC}"
    for file in /var/log/network/{172.16.0.1,172.16.0.2,172.16.0.3,172.16.0.4,192.168.0.130,192.168.0.2,192.168.1.250,192.168.1.242}.log; do
        if [ -f "$file" ] && [ -s "$file" ]; then
            basename=$(basename "$file")
            lines=$(wc -l < "$file")
            echo -e "${GREEN}✓ $basename: $lines líneas${NC}"
        fi
    done
    
    # Verificar Zabbix Agent
    echo -e "${YELLOW}4. Zabbix Agent:${NC}"
    if systemctl is-active --quiet zabbix-agent; then
        echo -e "${GREEN}✓ Zabbix Agent activo${NC}"
    else
        echo -e "${RED}✗ Zabbix Agent inactivo${NC}"
    fi
    
    echo
    read -p "Presiona Enter para continuar..."
}

# Función 2: Test UserParameters
test_all_userparameters() {
    clear
    echo -e "${CYAN}=== TEST USERPARAMETERS ===${NC}"
    
    log_action "Testing UserParameters"
    
    devices=("r1" "r2" "r3" "switch5" "switch6" "switch7" "switch8" "switch9")
    
    echo -e "${YELLOW}Testing UserParameters de todos los dispositivos:${NC}"
    echo
    
    for device in "${devices[@]}"; do
        printf "%-15s" "$device:"
        result=$(zabbix_agentd -t "network.log.$device" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$result" ]; then
            line_count=$(echo "$result" | wc -l)
            echo -e "${GREEN}✓ FUNCIONA ($line_count líneas)${NC}"
        else
            echo -e "${RED}✗ NO FUNCIONA${NC}"
        fi
    done
    
    echo
    read -p "Presiona Enter para continuar..."
}

# Función 3: Verificar NTP
verify_ntp_status() {
    clear
    echo -e "${CYAN}=== VERIFICACIÓN NTP ===${NC}"
    
    log_action "Verificando NTP en dispositivos"
    
    devices=(
        "192.168.1.250:R1"
        "192.168.1.242:R2" 
        "172.16.0.1:R3"
        "172.16.0.2:Switch7"
    )
    
    echo -e "${YELLOW}Verificando NTP en dispositivos principales:${NC}"
    echo
    
    for device in "${devices[@]}"; do
        IFS=':' read -ra DEV <<< "$device"
        ip=${DEV[0]}
        name=${DEV[1]}
        
        echo -e "${BLUE}--- $name ($ip) ---${NC}"
        sshpass -p 'cisco' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 admin@$ip << 'CISCO' 2>/dev/null
enable
cisco
show clock
show ntp status
exit
CISCO
        echo
    done
    
    echo
    read -p "Presiona Enter para continuar..."
}

# Función 4: Monitor logs en tiempo real
monitor_logs_realtime() {
    clear
    echo -e "${CYAN}=== MONITOR LOGS TIEMPO REAL ===${NC}"
    echo -e "${YELLOW}Presiona Ctrl+C para salir${NC}"
    echo
    
    log_action "Iniciando monitor de logs"
    
    # Monitor de logs principales
    while true; do
        clear
        echo -e "${CYAN}=== LOGS EN TIEMPO REAL - $(date) ===${NC}"
        echo
        
        # R3 (más activo)
        echo -e "${BLUE}R3 (172.16.0.1):${NC}"
        tail -2 /var/log/network/172.16.0.1.log 2>/dev/null | sed 's/^/  /'
        echo
        
        # Switch7 (core)
        echo -e "${BLUE}Switch7 (172.16.0.2):${NC}"
        tail -2 /var/log/network/172.16.0.2.log 2>/dev/null | sed 's/^/  /'
        echo
        
        # R1 y R2
        echo -e "${BLUE}R1 (192.168.1.250) y R2 (192.168.1.242):${NC}"
        tail -1 /var/log/network/192.168.1.250.log 2>/dev/null | sed 's/^/  /'
        tail -1 /var/log/network/192.168.1.242.log 2>/dev/null | sed 's/^/  /'
        
        sleep 5
    done
}

# Función 5: Test conectividad
test_connectivity() {
    clear
    echo -e "${CYAN}=== TEST CONECTIVIDAD COMPLETO ===${NC}"
    
    log_action "Test de conectividad completo"
    
    # Test ping a todos los dispositivos
    echo -e "${YELLOW}1. Test Ping a dispositivos:${NC}"
    devices=(
        "192.168.1.250:R1"
        "192.168.1.242:R2"
        "172.16.0.1:R3"
        "172.16.0.2:Switch7"
        "172.16.0.3:Switch6"
        "172.16.0.4:Switch5"
        "192.168.0.130:Switch8"
        "192.168.0.2:Switch9"
    )
    
    online_count=0
    for device in "${devices[@]}"; do
        IFS=':' read -ra DEV <<< "$device"
        ip=${DEV[0]}
        name=${DEV[1]}
        
        printf "%-30s" "  $name ($ip)"
        if ping -c 1 -W 2 $ip >/dev/null 2>&1; then
            echo -e "${GREEN}ONLINE${NC}"
            ((online_count++))
        else
            echo -e "${RED}OFFLINE${NC}"
        fi
    done
    
    echo
    echo -e "${BLUE}Resumen: $online_count/${#devices[@]} dispositivos online${NC}"
    
    # Test SSH a dispositivos principales
    echo
    echo -e "${YELLOW}2. Test SSH a dispositivos principales:${NC}"
    ssh_devices=(
        "192.168.1.250:R1"
        "192.168.1.242:R2"
        "172.16.0.1:R3"
        "172.16.0.2:Switch7"
    )
    
    for device in "${ssh_devices[@]}"; do
        IFS=':' read -ra DEV <<< "$device"
        ip=${DEV[0]}
        name=${DEV[1]}
        
        printf "%-30s" "  SSH $name ($ip)"
        if nc -z -w3 $ip 22 2>/dev/null; then
            echo -e "${GREEN}DISPONIBLE${NC}"
        else
            echo -e "${RED}NO DISPONIBLE${NC}"
        fi
    done
    
    echo
    read -p "Presiona Enter para continuar..."
}

# Función 6: Generar logs de prueba
generate_test_logs() {
    clear
    echo -e "${CYAN}=== GENERAR LOGS DE PRUEBA ===${NC}"
    
    log_action "Generando logs de prueba"
    
    # Función para enviar log
    send_test_log() {
        local device=$1
        local ip=$2
        local log_entry="<165>$(date +'%b %d %H:%M:%S') $device: %SYS-5-TEST: Test log generated at $(date)"
        
        echo "Enviando log de prueba a $device ($ip)..."
        if command -v nc >/dev/null 2>&1; then
            echo "$log_entry" | nc -u -w1 172.16.0.10 514
            echo -e "${GREEN}✓ Log enviado${NC}"
        else
            echo -e "${RED}✗ nc no disponible${NC}"
        fi
    }
    
    # Enviar logs a todos los dispositivos
    devices=(
        "R1:192.168.1.250"
        "R2:192.168.1.242" 
        "R3:172.16.0.1"
        "Switch7:172.16.0.2"
    )
    
    for device in "${devices[@]}"; do
        IFS=':' read -ra DEV <<< "$device"
        name=${DEV[0]}
        ip=${DEV[1]}
        send_test_log "$name" "$ip"
        sleep 1
    done
    
    echo
    echo -e "${YELLOW}Esperando procesar logs... (5 segundos)${NC}"
    sleep 5
    
    echo -e "${GREEN}Logs de prueba generados${NC}"
    echo
    read -p "Presiona Enter para continuar..."
}

# Función 7: Mantenimiento de logs
logs_maintenance() {
    clear
    echo -e "${CYAN}=== MANTENIMIENTO DE LOGS ===${NC}"
    
    log_action "Ejecutando mantenimiento de logs"
    
    LOG_DIR="/var/log/network"
    
    echo -e "${YELLOW}1. Espacio utilizado:${NC}"
    du -sh $LOG_DIR
    
    echo
    echo -e "${YELLOW}2. Archivos de log activos:${NC}"
    ls -lh $LOG_DIR/*.log | grep -v "^total"
    
    echo
    echo -e "${YELLOW}3. Comprimir logs antiguos (más de 7 días):${NC}"
    find $LOG_DIR -name "*.log" -mtime +7 -not -name "*.gz" -exec gzip {} \;
    echo -e "${GREEN}✓ Compresión completada${NC}"
    
    echo
    echo -e "${YELLOW}4. Eliminar logs muy antiguos (más de 30 días):${NC}"
    find $LOG_DIR -name "*.gz" -mtime +30 -delete
    echo -e "${GREEN}✓ Limpieza completada${NC}"
    
    echo
    read -p "Presiona Enter para continuar..."
}

# Función 8: Configurar NTP
configure_ntp() {
    clear
    echo -e "${CYAN}=== CONFIGURAR NTP/TIMEZONE ===${NC}"
    
    echo -e "${YELLOW}Configurando NTP en todos los dispositivos...${NC}"
    
    devices=(
        "192.168.1.250:R1"
        "192.168.1.242:R2"
        "172.16.0.1:R3"
        "172.16.0.2:Switch7"
        "172.16.0.3:Switch6"
        "172.16.0.4:Switch5"
        "192.168.0.130:Switch8"
        "192.168.0.2:Switch9"
    )
    
    for device in "${devices[@]}"; do
        IFS=':' read -ra DEV <<< "$device"
        ip=${DEV[0]}
        name=${DEV[1]}
        
        echo "Configurando $name ($ip)..."
        
        sshpass -p 'cisco' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 admin@$ip << 'EOF' >/dev/null 2>&1
enable
cisco
configure terminal
ntp server 172.16.0.10
clock timezone ECT -5
service timestamps log datetime localtime
service timestamps debug datetime localtime
exit
write memory
exit
EOF
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ $name configurado${NC}"
        else
            echo -e "${RED}✗ Error en $name${NC}"
        fi
    done
    
    echo
    echo -e "${GREEN}Configuración NTP completada${NC}"
    echo
    read -p "Presiona Enter para continuar..."
}

# Función 9: Mostrar configuración Zabbix Items
show_zabbix_config() {
    clear
    echo -e "${CYAN}=== CONFIGURACIÓN ZABBIX ITEMS ===${NC}"
    
    cat << 'EOF'
INSTRUCCIONES PARA CONFIGURAR ITEMS EN ZABBIX:

1. Ir a: http://172.16.0.10/zabbix
2. Configuration → Hosts → Zabbix server → Items
3. Create item para cada dispositivo:

ROUTERS:
========
R1: Name="Syslog - R1", Type=Zabbix agent, Key=network.log.r1
R2: Name="Syslog - R2", Type=Zabbix agent, Key=network.log.r2  
R3: Name="Syslog - R3", Type=Zabbix agent, Key=network.log.r3

SWITCHES:
=========
Switch5: Name="Syslog - Switch5", Key=network.log.switch5
Switch6: Name="Syslog - Switch6", Key=network.log.switch6
Switch7: Name="Syslog - Switch7", Key=network.log.switch7
Switch8: Name="Syslog - Switch8", Key=network.log.switch8
Switch9: Name="Syslog - Switch9", Key=network.log.switch9

CONFIGURACIÓN COMÚN:
===================
- Type of information: Text
- Host interface: 127.0.0.1:10050
- Update interval: 1m
- Custom intervals: 50s (1-7,00:00-24:00)
- Timeout: 3s
- History: 31d

DASHBOARD:
==========
Agregar widgets "Item value" para cada dispositivo en el dashboard
"NTP y SYSLOG".

EOF
    
    echo
    read -p "Presiona Enter para continuar..."
}

# Función principal
main() {
    # Verificar que estamos en el servidor correcto
    if [[ ! -f /etc/zabbix/zabbix_agentd.conf ]]; then
        echo -e "${RED}Error: Este script debe ejecutarse en el servidor Zabbix${NC}"
        exit 1
    fi
    
    # Crear log file si no existe
    sudo touch "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
    
    log_action "Script de administración iniciado"
    
    while true; do
        show_main_menu
        read -p "Selecciona una opción (0-9): " choice
        
        case $choice in
            1) verify_syslog_status ;;
            2) test_all_userparameters ;;
            3) verify_ntp_status ;;
            4) monitor_logs_realtime ;;
            5) test_connectivity ;;
            6) generate_test_logs ;;
            7) logs_maintenance ;;
            8) configure_ntp ;;
            9) show_zabbix_config ;;
            0) 
                echo -e "${GREEN}¡Administración completada!${NC}"
                log_action "Script finalizado"
                exit 0
                ;;
            *)
                echo -e "${RED}Opción inválida${NC}"
                sleep 1
                ;;
        esac
    done
}

# Ejecutar script
main
