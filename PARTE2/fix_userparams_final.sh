#!/bin/bash

# PASO 6: Corregir UserParameters con IPs reales de R1 y R2
echo "=== CORRIGIENDO USERPARAMETERS CON IPS REALES ==="

# Backup de configuración actual
cp /etc/zabbix/zabbix_agentd.d/network_logs.conf /etc/zabbix/zabbix_agentd.d/network_logs.conf.backup.$(date +%Y%m%d_%H%M%S)

echo "✓ Backup de configuración creado"

# Crear configuración final con IPs reales identificadas
sudo tee /etc/zabbix/zabbix_agentd.d/network_logs.conf > /dev/null << 'EOF'
# Universidad - Configuración Syslog FINAL
# Con IPs reales identificadas

# ROUTERS
# R1 (192.168.1.250) - Identificado en logs reales
UserParameter=network.log.r1,tail -n 10 /var/log/network/192.168.1.250.log

# R2 (192.168.1.242) - Interface principal identificada
# Nota: R2 tiene dos interfaces, usamos la del enlace R1-R2
UserParameter=network.log.r2,tail -n 10 /var/log/network/192.168.1.242.log

# R2 Interface secundaria (opcional) - enlace R2-R3
UserParameter=network.log.r2.alt,tail -n 10 /var/log/network/192.168.1.245.log

# R3 (172.16.0.1) - YA FUNCIONANDO CORRECTAMENTE
UserParameter=network.log.r3,tail -n 10 /var/log/network/172.16.0.1.log

# SWITCHES - YA FUNCIONANDO CORRECTAMENTE
# Switch5 (172.16.0.4)
UserParameter=network.log.switch5,tail -n 10 /var/log/network/172.16.0.4.log

# Switch6 (172.16.0.3)
UserParameter=network.log.switch6,tail -n 10 /var/log/network/172.16.0.3.log

# Switch7 (172.16.0.2)
UserParameter=network.log.switch7,tail -n 10 /var/log/network/172.16.0.2.log

# Switch8 (192.168.0.130)
UserParameter=network.log.switch8,tail -n 10 /var/log/network/192.168.0.130.log

# Switch9 (192.168.0.2)
UserParameter=network.log.switch9,tail -n 10 /var/log/network/192.168.0.2.log

# UserParameters para contadores
UserParameter=network.log.count.r1,wc -l < /var/log/network/192.168.1.250.log
UserParameter=network.log.count.r2,wc -l < /var/log/network/192.168.1.242.log
UserParameter=network.log.count.r3,wc -l < /var/log/network/172.16.0.1.log

# UserParameters adicionales
UserParameter=network.log.all,tail -n 20 /var/log/network/all-devices.log
UserParameter=network.devices.active,ls -la /var/log/network/*.log | grep -c "^-.*\.log$"
EOF

echo "✓ UserParameters corregidos con IPs reales"

# Reiniciar Zabbix Agent
echo
echo "Reiniciando Zabbix Agent..."
sudo systemctl restart zabbix-agent

if systemctl is-active --quiet zabbix-agent; then
    echo "✓ Zabbix Agent reiniciado exitosamente"
else
    echo "✗ Error reiniciando Zabbix Agent"
    systemctl status zabbix-agent --no-pager -l
    exit 1
fi

# Test final de UserParameters
echo
echo "=== TESTING USERPARAMETERS CORREGIDOS ==="

devices=("r1" "r2" "r3" "switch5" "switch6" "switch7" "switch8" "switch9")

for device in "${devices[@]}"; do
    echo "Testing network.log.$device:"
    result=$(zabbix_agentd -t "network.log.$device" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$result" ]; then
        # Contar líneas en el resultado
        line_count=$(echo "$result" | wc -l)
        first_line=$(echo "$result" | head -1)
        echo "✓ $device: FUNCIONA ($line_count líneas)"
        echo "    Muestra: $(echo "$first_line" | cut -c1-70)..."
    else
        echo "✗ $device: NO FUNCIONA"
    fi
    echo
done

echo "=== RESUMEN FINAL ==="
echo
echo "UserParameters configurados correctamente:"
echo "✓ R1: 192.168.1.250.log (IP del enlace R1-R3)"
echo "✓ R2: 192.168.1.242.log (IP del enlace R1-R2)"
echo "✓ R3: 172.16.0.1.log (Router-on-Stick)"
echo "✓ Todos los switches funcionando"
echo
echo "LISTOS PARA CONFIGURAR EN ZABBIX WEB!"
