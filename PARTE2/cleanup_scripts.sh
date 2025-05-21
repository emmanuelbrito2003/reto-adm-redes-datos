#!/bin/bash

# Script para limpiar archivos innecesarios y dejar solo los esenciales
echo "=== LIMPIEZA DE SCRIPTS INNECESARIOS ==="

# Crear backup
mkdir -p /root/backup_scripts_$(date +%Y%m%d)
echo "✓ Directorio de backup creado"

# Scripts a mantener (esenciales)
KEEP_SCRIPTS=(
    "network_ssh.sh"
    "fix_userparams_final.sh" 
    "config_ntp.sh"
    "config_timezone.sh"
    "verify_ntp.sh"
    "monitor_network_logs.sh"
    "syslog_maintenance.sh"
    "test_syslog_improved.sh"
)

# Scripts a eliminar (hacer backup primero)
REMOVE_SCRIPTS=(
    "complete_syslog_fix.sh"
    "configure_syslog_items_zabbix.sh"
    "configure_syslog_zabbix.sh"
    "configure_zabbix_existing_logs.sh"
    "configure_zabbix_syslog.py"
    "fix_rsyslog_separation.sh"
    "fix_userparameters.sh"
    "generate_test_logs_r1_r2.sh"
    "investigate_real_ips.sh"
    "test_syslog.sh"
    "test_userparameters.sh"
    "verify_r3_config.sh"
    "zabbix_items_alternative.txt"
    "zabbix_items_by_ip.txt"
)

echo
echo "Haciendo backup de scripts a eliminar..."
for script in "${REMOVE_SCRIPTS[@]}"; do
    if [ -f "/root/$script" ]; then
        cp "/root/$script" "/root/backup_scripts_$(date +%Y%m%d)/"
        echo "  ✓ Backup: $script"
    fi
done

echo
echo "Eliminando scripts redundantes..."
for script in "${REMOVE_SCRIPTS[@]}"; do
    if [ -f "/root/$script" ]; then
        rm "/root/$script"
        echo "  ✗ Eliminado: $script"
    fi
done

echo
echo "Scripts mantenidos (esenciales):"
for script in "${KEEP_SCRIPTS[@]}"; do
    if [ -f "/root/$script" ]; then
        echo "  ✓ $script"
    fi
done

echo
echo "=== LIMPIEZA COMPLETADA ==="
echo "Backup disponible en: /root/backup_scripts_$(date +%Y%m%d)/"
echo

# Mostrar estado final del directorio
echo "Estado final del directorio /root:"
ls -la /root/*.sh 2>/dev/null | grep -v "total"
