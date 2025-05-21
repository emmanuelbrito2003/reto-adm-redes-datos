#!/usr/bin/env python3
"""
Script de administración de red - Universidad
Parte III - Administración de Redes

Este script proporciona funciones para administrar dispositivos de red:
- Backup de configuraciones
- Escaneo de interfaces
- Diagnóstico de conectividad
- Gestión básica de configuraciones
"""

import os
import sys
import yaml
import logging
import argparse
import datetime
import netmiko
import re
from concurrent.futures import ThreadPoolExecutor

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/root/network_automation/logs/network_admin.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('network_admin')

# Directorios y archivos
BASE_DIR = '/root/network_automation'
CONFIG_DIR = os.path.join(BASE_DIR, 'configs')
BACKUP_DIR = os.path.join(BASE_DIR, 'backups')
DEVICES_FILE = os.path.join(CONFIG_DIR, 'devices.yaml')

def load_devices():
    """Cargar configuración de dispositivos desde YAML"""
    try:
        with open(DEVICES_FILE, 'r') as f:
            return yaml.safe_load(f)
    except Exception as e:
        logger.error(f"Error cargando configuración: {e}")
        return None

def connect_to_device(device_info):
    """Establecer conexión SSH a un dispositivo"""
    try:
        device_params = {
            'device_type': device_info['type'],
            'host': device_info['ip'],
            'username': device_info['username'],
            'password': device_info['password'],
            'timeout': 10,
            'session_log': None
        }
        
        logger.info(f"Conectando a {device_info['ip']}...")
        
        # Intentar conexión con parámetros específicos para Cisco legacy
        connection = netmiko.ConnectHandler(**device_params)
        logger.info(f"Conexión exitosa a {device_info['ip']}")
        return connection
    except Exception as e:
        logger.error(f"Error conectando a {device_info['ip']}: {e}")
        return None

def backup_device_config(device_name, device_info):
    """Realiza backup de la configuración de un dispositivo"""
    try:
        from netmiko import ConnectHandler
        import datetime
        import os
        
        # Directorio para backups
        backup_dir = "/root/network_automation/backups"
        os.makedirs(backup_dir, exist_ok=True)
        
        # Crear nombre de archivo con timestamp
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = os.path.join(backup_dir, f"{device_name}_{timestamp}.txt")
        
        # Información de conexión
        device = {
            'device_type': device_info['type'],
            'ip': device_info['ip'],
            'username': device_info['username'],
            'password': device_info['password'],
            'secret': device_info.get('secret', device_info['password']),  # Usar password como secret si no está especificado
        }
        
        # Conectar al dispositivo
        print(f"Conectando a {device_name} ({device_info['ip']})...")
        with ConnectHandler(**device) as conn:
            # Entrar en modo privilegiado
            conn.enable()
            
            # Obtener configuración running (cambiar el comando según sea necesario)
            # Usamos terminal length 0 para que no pagine el output
            conn.send_command('terminal length 0')
            output = conn.send_command('show running-config')
            
            # Guardar la salida en un archivo
            with open(backup_file, 'w') as f:
                f.write(output)
            
            print(f"Backup de {device_name} guardado en {backup_file}")
            
            return backup_file
    except Exception as e:
        print(f"Error realizando backup de {device_name}: {e}")
        return None

def backup_all_devices():
    """Realizar backup de todos los dispositivos configurados"""
    data = load_devices()
    if not data:
        logger.error("No se pudo cargar configuración de dispositivos")
        return
    
    results = {"success": [], "failed": []}
    
    # Backup de routers
    logger.info("Realizando backup de routers...")
    for name, info in data['devices']['routers'].items():
        result = backup_device_config(name, info)
        if result:
            results["success"].append(name)
        else:
            results["failed"].append(name)
    
    # Backup de switches
    logger.info("Realizando backup de switches...")
    for name, info in data['devices']['switches'].items():
        result = backup_device_config(name, info)
        if result:
            results["success"].append(name)
        else:
            results["failed"].append(name)
    
    # Mostrar resultados
    print("\nResumen de backup:")
    print(f"Exitosos: {len(results['success'])}")
    print(f"Fallidos: {len(results['failed'])}")
    
    if results["success"]:
        print("\nDispositivos con backup exitoso:")
        for device in results["success"]:
            print(f"  ✓ {device}")
    
    if results["failed"]:
        print("\nDispositivos con backup fallido:")
        for device in results["failed"]:
            print(f"  ✗ {device}")
    
    return results

def get_interfaces(device_name, device_info):
    """Obtener información de interfaces de un dispositivo"""
    connection = connect_to_device(device_info)
    if not connection:
        return None
    
    try:
        # Obtener interfaces
        interfaces = connection.send_command("show ip interface brief")
        connection.disconnect()
        
        # Analizar la información
        interfaces_info = []
        for line in interfaces.split("\n"):
            if "unassigned" in line or "not set" in line:
                continue
            
            # Extraer información relevante para interfaces con IP
            match = re.search(r"(\S+)\s+(\d+\.\d+\.\d+\.\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)", line)
            if match:
                interface_name = match.group(1)
                ip_address = match.group(2)
                status = match.group(5)
                protocol = match.group(6)
                
                interfaces_info.append({
                    "name": interface_name,
                    "ip": ip_address,
                    "status": status,
                    "protocol": protocol
                })
        
        return interfaces_info
    except Exception as e:
        logger.error(f"Error obteniendo interfaces de {device_name}: {e}")
        if connection:
            connection.disconnect()
        return None

def scan_all_interfaces():
    """Escanear interfaces de todos los dispositivos"""
    data = load_devices()
    if not data:
        logger.error("No se pudo cargar configuración de dispositivos")
        return
    
    results = {}
    
    # Escanear interfaces de routers
    logger.info("Escaneando interfaces de routers...")
    for name, info in data['devices']['routers'].items():
        interfaces = get_interfaces(name, info)
        if interfaces:
            results[name] = interfaces
            logger.info(f"Escaneadas {len(interfaces)} interfaces de {name}")
    
    # Escanear interfaces de switches con IP
    logger.info("Escaneando interfaces de switches...")
    for name, info in data['devices']['switches'].items():
        interfaces = get_interfaces(name, info)
        if interfaces:
            results[name] = interfaces
            logger.info(f"Escaneadas {len(interfaces)} interfaces de {name}")
    
    # Mostrar resultados
    print("\nResumen de interfaces:")
    total_interfaces = sum(len(interfaces) for interfaces in results.values())
    print(f"Total dispositivos escaneados: {len(results)}")
    print(f"Total interfaces encontradas: {total_interfaces}")
    
    print("\nInterfaces por dispositivo:")
    for device, interfaces in results.items():
        print(f"\n{device}:")
        for interface in interfaces:
            status_color = "✓" if interface["status"] == "up" else "✗"
            print(f"  {status_color} {interface['name']} - {interface['ip']} ({interface['status']}/{interface['protocol']})")
    
    return results

def test_connectivity(device_name, device_info, target_ip):
    """Probar conectividad desde un dispositivo a una IP destino"""
    connection = connect_to_device(device_info)
    if not connection:
        return None
    
    try:
        # Ejecutar ping desde el dispositivo
        output = connection.send_command(f"ping {target_ip}")
        connection.disconnect()
        
        # Analizar resultado
        if "Success rate is 0 percent" in output:
            return {"success": False, "output": output}
        elif "Success rate is" in output:
            # Extraer tasa de éxito
            match = re.search(r"Success rate is (\d+) percent", output)
            success_rate = int(match.group(1)) if match else 0
            return {"success": success_rate > 0, "success_rate": success_rate, "output": output}
        else:
            return {"success": False, "output": output}
    except Exception as e:
        logger.error(f"Error probando conectividad desde {device_name} a {target_ip}: {e}")
        if connection:
            connection.disconnect()
        return None

def test_all_connectivity(target_ip):
    """Probar conectividad desde todos los dispositivos a una IP destino"""
    data = load_devices()
    if not data:
        logger.error("No se pudo cargar configuración de dispositivos")
        return
    
    print(f"\nProbando conectividad a {target_ip} desde todos los dispositivos...")
    results = {"success": [], "failed": []}
    
    # Probar desde routers
    for name, info in data['devices']['routers'].items():
        logger.info(f"Probando desde {name} a {target_ip}...")
        result = test_connectivity(name, info, target_ip)
        
        if result and result["success"]:
            success_rate = result.get("success_rate", 100)
            results["success"].append({"device": name, "success_rate": success_rate})
            print(f"  ✓ {name}: Exitoso ({success_rate}% de éxito)")
        else:
            results["failed"].append({"device": name})
            print(f"  ✗ {name}: Fallido")
    
    # Probar desde switches (solo los que tengan IP)
    for name, info in data['devices']['switches'].items():
        logger.info(f"Probando desde {name} a {target_ip}...")
        result = test_connectivity(name, info, target_ip)
        
        if result and result["success"]:
            success_rate = result.get("success_rate", 100)
            results["success"].append({"device": name, "success_rate": success_rate})
            print(f"  ✓ {name}: Exitoso ({success_rate}% de éxito)")
        else:
            results["failed"].append({"device": name})
            print(f"  ✗ {name}: Fallido")
    
    # Mostrar resumen
    print("\nResumen de prueba de conectividad:")
    print(f"Exitosos: {len(results['success'])}")
    print(f"Fallidos: {len(results['failed'])}")
    
    return results

def configure_ntp(device_name, device_info, ntp_server):
    """Configurar servidor NTP en un dispositivo"""
    connection = connect_to_device(device_info)
    if not connection:
        return False
    
    try:
        # Configurar NTP
        commands = [
            "configure terminal",
            f"ntp server {ntp_server}",
            "exit"
        ]
        
        output = connection.send_config_set(commands)
        connection.save_config()
        connection.disconnect()
        
        logger.info(f"NTP configurado en {device_name}: {ntp_server}")
        return True
    except Exception as e:
        logger.error(f"Error configurando NTP en {device_name}: {e}")
        if connection:
            connection.disconnect()
        return False

def configure_all_ntp(ntp_server):
    """Configurar NTP en todos los dispositivos"""
    data = load_devices()
    if not data:
        logger.error("No se pudo cargar configuración de dispositivos")
        return
    
    print(f"\nConfigurando NTP ({ntp_server}) en todos los dispositivos...")
    results = {"success": [], "failed": []}
    
    # Configurar en routers
    for name, info in data['devices']['routers'].items():
        logger.info(f"Configurando NTP en {name}...")
        result = configure_ntp(name, info, ntp_server)
        
        if result:
            results["success"].append(name)
            print(f"  ✓ {name}: Configurado")
        else:
            results["failed"].append(name)
            print(f"  ✗ {name}: Fallido")
    
    # Configurar en switches
    for name, info in data['devices']['switches'].items():
        logger.info(f"Configurando NTP en {name}...")
        result = configure_ntp(name, info, ntp_server)
        
        if result:
            results["success"].append(name)
            print(f"  ✓ {name}: Configurado")
        else:
            results["failed"].append(name)
            print(f"  ✗ {name}: Fallido")
    
    # Mostrar resumen
    print("\nResumen de configuración NTP:")
    print(f"Exitosos: {len(results['success'])}")
    print(f"Fallidos: {len(results['failed'])}")
    
    return results

def main():
    """Función principal"""
    parser = argparse.ArgumentParser(description="Administración de Red - Universidad")
    parser.add_argument("--backup", action="store_true", help="Realizar backup de configuraciones")
    parser.add_argument("--interfaces", action="store_true", help="Escanear interfaces de dispositivos")
    parser.add_argument("--ping", type=str, help="Probar conectividad desde todos los dispositivos a una IP")
    parser.add_argument("--ntp", type=str, help="Configurar NTP en todos los dispositivos")
    
    args = parser.parse_args()
    
    if args.backup:
        backup_all_devices()
    elif args.interfaces:
        scan_all_interfaces()
    elif args.ping:
        test_all_connectivity(args.ping)
    elif args.ntp:
        configure_all_ntp(args.ntp)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
