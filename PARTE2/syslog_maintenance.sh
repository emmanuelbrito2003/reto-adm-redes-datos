#!/bin/bash

# Script de mantenimiento para logs de red
# Universidad - Proyecto Final

LOG_DIR="/var/log/network"
RETENTION_DAYS=30

echo "=== MANTENIMIENTO DE LOGS DE RED ==="
echo "Directorio: $LOG_DIR"
echo "Retención: $RETENTION_DAYS días"
echo

# Comprimir logs antiguos
echo "Comprimiendo logs antiguos..."
find $LOG_DIR -name "*.log" -mtime +7 -not -name "*.gz" -exec gzip {} \;

# Eliminar logs muy antiguos
echo "Eliminando logs más antiguos que $RETENTION_DAYS días..."
find $LOG_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete

# Verificar espacio en disco
echo "Espacio utilizado en $LOG_DIR:"
du -sh $LOG_DIR

# Verificar últimos logs
echo "Últimos logs recibidos:"
ls -lt $LOG_DIR/*.log | head -5

echo "=== MANTENIMIENTO COMPLETADO ==="
