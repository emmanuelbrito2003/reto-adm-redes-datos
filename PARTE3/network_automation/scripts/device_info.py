#!/usr/bin/env python3
"""
Script template para automatizacion de red
Universidad - Parte III del proyecto
"""

import yaml
from netmiko import ConnectHandler
import sys
import argparse

def load_devices():
    """Cargar configuracion de dispositivos"""
    with open('/root/network_automation/configs/devices.yaml', 'r') as f:
        return yaml.safe_load(f)

def connect_device(device_config):
    """Conectar a dispositivo usando netmiko"""
    try:
        connection = ConnectHandler(**device_config)
        return connection
    except Exception as e:
        print(f"Error conectando: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description='Obtener informacion de dispositivos')
    parser.add_argument('--device', help='Nombre del dispositivo')
    parser.add_argument('--type', choices=['router', 'switch'], help='Tipo de dispositivo')
    
    args = parser.parse_args()
    
    # Cargar configuracion
    config = load_devices()
    
    # Ejemplo de uso
    print("Template script ready for automation")
    print("Dispositivos disponibles:")
    
    for category in ['routers', 'switches']:
        print(f"\n{category.upper()}:")
        for name, details in config['devices'][category].items():
            print(f"  - {name}: {details['ip']}")

if __name__ == "__main__":
    main()
