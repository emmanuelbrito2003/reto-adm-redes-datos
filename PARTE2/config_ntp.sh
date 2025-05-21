#!/bin/bash

# Script CORREGIDO para cambiar NTP a Zabbix en todos los dispositivos
echo "=== CONFIGURANDO ZABBIX COMO SERVIDOR NTP (CORREGIDO) ==="
echo

# Lista de dispositivos
devices=(
    "192.168.1.241:R1"
    "192.168.0.1:R2"
    "172.16.0.1:R3"
    "172.16.0.2:Switch7"
    "172.16.0.3:Switch6"
    "172.16.0.4:Switch5"
    "192.168.0.130:Switch8"
    "192.168.0.2:Switch9"
)

# Configurar cada dispositivo
for device in "${devices[@]}"; do
    IFS=':' read -ra DEV <<< "$device"
    ip=${DEV[0]}
    name=${DEV[1]}
    
    echo "Configurando NTP en $name ($ip)..."
    
    # Configurar via SSH con enable y contraseña
    sshpass -p 'cisco' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 admin@$ip << 'EOF'
enable
cisco
configure terminal
no ntp server 0.pool.ntp.org
no ntp server pool.ntp.org
ntp server 172.16.0.10
exit
write memory
exit
EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ $name configurado correctamente"
    else
        echo "❌ Error configurando $name"
    fi
    sleep 2
done

echo
echo "=== VERIFICANDO CLIENTES NTP ==="
sleep 15
chronyc clients
echo "=== CONFIGURACIÓN COMPLETADA ==="
