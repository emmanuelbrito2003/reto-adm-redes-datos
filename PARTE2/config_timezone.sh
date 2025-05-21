#!/bin/bash

# Script para configurar zona horaria Ecuador en dispositivos
echo "=== CONFIGURANDO ZONA HORARIA ECUADOR ==="
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
    
    echo "Configurando zona horaria en $name ($ip)..."
    
    # Configurar zona horaria Ecuador
    sshpass -p 'cisco' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 admin@$ip << 'EOF'
enable
cisco
configure terminal
clock timezone ECT -5
ntp update-calendar
service timestamps log datetime localtime
service timestamps debug datetime localtime
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
echo "=== VERIFICANDO HORA EN DISPOSITIVOS ==="
echo "Esperando sincronización..."
sleep 10

# Verificar hora en algunos dispositivos
test_devices=("192.168.1.241:R1" "172.16.0.1:R3")

for device in "${test_devices[@]}"; do
    IFS=':' read -ra DEV <<< "$device"
    ip=${DEV[0]}
    name=${DEV[1]}
    
    echo "--- Hora en $name ---"
    sshpass -p 'cisco' ssh -o StrictHostKeyChecking=no admin@$ip "enable" "cisco" "show clock" 2>/dev/null
done

echo "=== CONFIGURACIÓN COMPLETADA ==="
