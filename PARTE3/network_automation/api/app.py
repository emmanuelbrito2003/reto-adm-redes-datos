#!/usr/bin/env python3
"""
API REST para Administración de Red - Universidad
Parte III - Administración de Redes

API para gestión remota de dispositivos de red con Dashboard Interactivo
"""

from flask import Flask, jsonify, request, render_template_string
from flask_restful import Api, Resource
import os
import sys
import yaml
import json
import logging
import subprocess
import datetime

# Ajustar path para importar módulos locales
BASE_DIR = '/root/network_automation'
API_DIR = os.path.join(BASE_DIR, 'api')
SCRIPTS_DIR = os.path.join(BASE_DIR, 'scripts')
CONFIG_DIR = os.path.join(BASE_DIR, 'configs')
BACKUP_DIR = os.path.join(BASE_DIR, 'backups')
LOG_DIR = os.path.join(BASE_DIR, 'logs')

# Asegurar que podemos importar scripts
sys.path.append(SCRIPTS_DIR)

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(LOG_DIR, 'api.log')),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('api')

# Crear aplicación Flask
app = Flask(__name__)
api = Api(app)

# Archivo de dispositivos
DEVICES_FILE = os.path.join(CONFIG_DIR, 'devices.yaml')

# Función para cargar dispositivos
def load_devices():
    """Cargar dispositivos desde archivo YAML"""
    try:
        with open(DEVICES_FILE, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except Exception as e:
        logger.error(f"Error cargando devices.yaml: {e}")
        return None

# Plantilla HTML mejorada para el dashboard interactivo
INTERACTIVE_DASHBOARD = """
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard de Administración de Red - Universidad</title>
    <style>
        :root {
            --primary: #3498db;
            --secondary: #2c3e50;
            --success: #2ecc71;
            --danger: #e74c3c;
            --warning: #f39c12;
            --light: #ecf0f1;
            --dark: #34495e;
            --border-radius: 6px;
        }
        
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f5f5f5;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: var(--border-radius);
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 20px;
        }
        
        header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
            margin-bottom: 20px;
        }
        
        h1 {
            color: var(--secondary);
            font-size: 24px;
        }
        
        .header-right {
            display: flex;
            align-items: center;
        }
        
        .api-status {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 50px;
            background: var(--success);
            color: white;
            font-size: 14px;
            margin-left: 15px;
        }
        
        .card {
            background: white;
            border-radius: var(--border-radius);
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            overflow: hidden;
        }
        
        .card-header {
            background: var(--secondary);
            color: white;
            padding: 12px 15px;
            font-weight: 600;
        }
        
        .card-body {
            padding: 15px;
        }
        
        .tabs {
            display: flex;
            border-bottom: 1px solid #ddd;
            margin-bottom: 20px;
        }
        
        .tab {
            padding: 10px 20px;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            transition: all 0.3s;
        }
        
        .tab.active {
            border-bottom: 3px solid var(--primary);
            color: var(--primary);
            font-weight: 600;
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .form-group {
            margin-bottom: 15px;
        }
        
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: 600;
            color: var(--secondary);
        }
        
        select, input, button {
            width: 100%;
            padding: 10px;
            border-radius: var(--border-radius);
            border: 1px solid #ddd;
            font-size: 16px;
        }
        
        button {
            background: var(--primary);
            color: white;
            border: none;
            padding: 12px;
            cursor: pointer;
            font-weight: 600;
            transition: background 0.3s;
        }
        
        button:hover {
            background: #2980b9;
        }
        
        .row {
            display: flex;
            margin: 0 -10px;
        }
        
        .col {
            flex: 1;
            padding: 0 10px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        
        th {
            background-color: #f8f9fa;
            font-weight: 600;
            color: var(--secondary);
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .result-area {
            background: #f8f9fa;
            border-radius: var(--border-radius);
            padding: 15px;
            min-height: 200px;
            max-height: 500px;
            overflow-y: auto;
            border: 1px solid #ddd;
            white-space: pre-wrap;
            font-family: monospace;
        }
        
        .endpoint-card {
            border: 1px solid #ddd;
            border-radius: var(--border-radius);
            margin-bottom: 10px;
            overflow: hidden;
        }
        
        .endpoint-header {
            padding: 10px 15px;
            background: #f5f5f5;
            font-weight: 600;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .endpoint-body {
            padding: 15px;
            border-top: 1px solid #ddd;
            display: none;
        }
        
        .method {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            margin-right: 10px;
        }
        
        .method.get {
            background: #61affe;
            color: white;
        }
        
        .method.post {
            background: #49cc90;
            color: white;
        }
        
        .loading {
            text-align: center;
            padding: 20px;
            display: none;
        }
        
        .loading:after {
            content: "⏳";
            animation: loading 1s infinite;
            font-size: 24px;
        }
        
        @keyframes loading {
            0% { opacity: 0.2; }
            50% { opacity: 1; }
            100% { opacity: 0.2; }
        }
        
        .alert {
            padding: 12px 15px;
            border-radius: var(--border-radius);
            margin-bottom: 15px;
            color: white;
        }
        
        .alert-success {
            background: var(--success);
        }
        
        .alert-danger {
            background: var(--danger);
        }
        
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 50px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .badge-success {
            background: var(--success);
            color: white;
        }
        
        .badge-danger {
            background: var(--danger);
            color: white;
        }
        
        .badge-warning {
            background: var(--warning);
            color: white;
        }
        
        .endpoint-example {
            background: #272c35;
            color: white;
            padding: 12px;
            border-radius: 4px;
            margin-top: 10px;
            font-family: monospace;
            overflow-x: auto;
        }
        
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #777;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Dashboard de Administración de Red - Universidad</h1>
            <div class="header-right">
                <div id="current-time"></div>
                <div class="api-status">API Online</div>
            </div>
        </header>
        
        <div class="tabs">
            <div class="tab active" data-tab="dashboard">Dashboard</div>
            <div class="tab" data-tab="devices">Dispositivos</div>
            <div class="tab" data-tab="operations">Operaciones</div>
            <div class="tab" data-tab="api-docs">Documentación API</div>
        </div>
        
        <!-- Tab Dashboard -->
        <div class="tab-content active" id="dashboard-tab">
            <div class="row">
                <div class="col">
                    <div class="card">
                        <div class="card-header">Resumen del Sistema</div>
                        <div class="card-body">
                            <p><strong>API Version:</strong> 1.0.0</p>
                            <p><strong>Routers:</strong> <span id="router-count">{{ routers_count }}</span></p>
                            <p><strong>Switches:</strong> <span id="switch-count">{{ switches_count }}</span></p>
                            <p><strong>Estado API:</strong> <span class="badge badge-success">Online</span></p>
                            <p><strong>Última actualización:</strong> <span id="last-update">{{ current_time }}</span></p>
                        </div>
                    </div>
                </div>
                <div class="col">
                    <div class="card">
                        <div class="card-header">Acciones Rápidas</div>
                        <div class="card-body">
                            <div class="form-group">
                                <button id="quick-backup" type="button">Backup de Todos los Dispositivos</button>
                            </div>
                            <div class="form-group">
                                <button id="quick-interfaces" type="button">Escanear Interfaces</button>
                            </div>
                            <div class="form-group">
                                <button id="quick-ping" type="button">Test Ping a 8.8.8.8</button>
                            </div>
                            <div class="form-group">
                                <button id="quick-ntp" type="button">Configurar NTP (172.16.0.10)</button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">Resultados</div>
                <div class="card-body">
                    <div id="loading" class="loading"></div>
                    <div id="result-container" class="result-area">Selecciona una operación para ver los resultados...</div>
                </div>
            </div>
        </div>
        
        <!-- Tab Dispositivos -->
        <div class="tab-content" id="devices-tab">
            <div class="card">
                <div class="card-header">Dispositivos Configurados</div>
                <div class="card-body">
                    <table>
                        <thead>
                            <tr>
                                <th>Tipo</th>
                                <th>Nombre</th>
                                <th>Dirección IP</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for device_type, devices in device_data.items() %}
                                {% for name, info in devices.items() %}
                                <tr>
                                    <td>{{ device_type.capitalize() }}</td>
                                    <td>{{ name }}</td>
                                    <td>{{ info.ip }}</td>
                                    <td>
                                        <button class="device-info" data-device="{{ name }}">Info</button>
                                        <button class="device-interfaces" data-device="{{ name }}">Interfaces</button>
                                        <button class="device-backup" data-device="{{ name }}">Backup</button>
                                    </td>
                                </tr>
                                {% endfor %}
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">Información del Dispositivo</div>
                <div class="card-body">
                    <div id="device-loading" class="loading"></div>
                    <div id="device-result" class="result-area">Selecciona un dispositivo para ver detalles...</div>
                </div>
            </div>
        </div>
        
        <!-- Tab Operaciones -->
        <div class="tab-content" id="operations-tab">
            <div class="row">
                <div class="col">
                    <div class="card">
                        <div class="card-header">Operaciones Disponibles</div>
                        <div class="card-body">
                            <div class="form-group">
                                <label for="operation-select">Selecciona Operación:</label>
                                <select id="operation-select">
                                    <option value="">-- Selecciona una operación --</option>
                                    <option value="get-interfaces">Escaneo de Interfaces</option>
                                    <option value="ping-test">Test de Ping</option>
                                    <option value="backup">Backup de Configuración</option>
                                    <option value="ntp">Configuración de NTP</option>
                                </select>
                            </div>
                            
                            <div id="operation-params">
                                <!-- Parámetros dinámicos según la operación -->
                            </div>
                            
                            <div class="form-group">
                                <button id="execute-operation" type="button" disabled>Ejecutar Operación</button>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col">
                    <div class="card">
                        <div class="card-header">Descripción</div>
                        <div class="card-body">
                            <div id="operation-description">
                                Selecciona una operación para ver su descripción...
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <div class="card-header">Resultados de la Operación</div>
                <div class="card-body">
                    <div id="op-loading" class="loading"></div>
                    <div id="operation-result" class="result-area">Ejecuta una operación para ver los resultados...</div>
                </div>
            </div>
        </div>
        
        <!-- Tab API Docs -->
        <div class="tab-content" id="api-docs-tab">
            <div class="card">
                <div class="card-header">Documentación de la API</div>
                <div class="card-body">
                    <p>Esta API permite la gestión remota de dispositivos de red mediante servicios REST.</p>
                    
                    <h3 style="margin-top: 20px; margin-bottom: 10px;">Endpoints Disponibles</h3>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method get">GET</span> /api/health
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Verificar estado de la API</p>
                            <div class="endpoint-example">curl http://{{ request.host }}/api/health</div>
                        </div>
                    </div>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method get">GET</span> /api/devices
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Obtener lista de dispositivos configurados</p>
                            <div class="endpoint-example">curl http://{{ request.host }}/api/devices</div>
                        </div>
                    </div>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method get">GET</span> /api/devices/&lt;device_name&gt;
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Obtener información de un dispositivo específico</p>
                            <div class="endpoint-example">curl http://{{ request.host }}/api/devices/R1</div>
                        </div>
                    </div>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method get">GET</span> /api/interfaces
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Obtener interfaces de todos los dispositivos</p>
                            <div class="endpoint-example">curl http://{{ request.host }}/api/interfaces</div>
                        </div>
                    </div>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method get">GET</span> /api/interfaces/&lt;device_name&gt;
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Obtener interfaces de un dispositivo específico</p>
                            <div class="endpoint-example">curl http://{{ request.host }}/api/interfaces/R1</div>
                        </div>
                    </div>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method post">POST</span> /api/backup
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Realizar backup de configuraciones</p>
                            <div class="endpoint-example">curl -X POST http://{{ request.host }}/api/backup</div>
                        </div>
                    </div>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method post">POST</span> /api/backup/&lt;device_name&gt;
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Realizar backup de un dispositivo específico</p>
                            <div class="endpoint-example">curl -X POST http://{{ request.host }}/api/backup/R1</div>
                        </div>
                    </div>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method post">POST</span> /api/ping
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Verificar conectividad a una IP desde todos los dispositivos</p>
                            <div class="endpoint-example">curl -X POST -H "Content-Type: application/json" -d '{"target": "8.8.8.8"}' http://{{ request.host }}/api/ping</div>
                        </div>
                    </div>
                    
                    <div class="endpoint-card">
                        <div class="endpoint-header">
                            <div>
                                <span class="method post">POST</span> /api/ntp
                            </div>
                            <span>⯆</span>
                        </div>
                        <div class="endpoint-body">
                            <p>Configurar NTP en todos los dispositivos</p>
                            <div class="endpoint-example">curl -X POST -H "Content-Type: application/json" -d '{"server": "172.16.0.10"}' http://{{ request.host }}/api/ntp</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>API de Administración de Red - Universidad | Parte III - Administración de Redes</p>
        </div>
    </div>
    
    <script>
        // Actualizar reloj
        function updateClock() {
            const now = new Date();
            document.getElementById('current-time').textContent = now.toLocaleString();
        }
        setInterval(updateClock, 1000);
        updateClock();
        
        // Tabs
        document.querySelectorAll('.tab').forEach(tab => {
            tab.addEventListener('click', () => {
                // Desactivar todos los tabs
                document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
                document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
                
                // Activar el tab seleccionado
                tab.classList.add('active');
                const tabId = tab.getAttribute('data-tab') + '-tab';
                document.getElementById(tabId).classList.add('active');
            });
        });
        
        // Mostrar/ocultar detalles de endpoint
        document.querySelectorAll('.endpoint-header').forEach(header => {
            header.addEventListener('click', () => {
                const body = header.nextElementSibling;
                const isVisible = body.style.display === 'block';
                body.style.display = isVisible ? 'none' : 'block';
            });
        });
        
        // Funciones de API
        async function callApi(url, method = 'GET', data = null) {
            const options = {
                method,
                headers: {
                    'Content-Type': 'application/json'
                }
            };
            
            if (data) {
                options.body = JSON.stringify(data);
            }
            
            try {
                const response = await fetch(url, options);
                return await response.json();
            } catch (error) {
                console.error('Error en llamada API:', error);
                return { error: 'Error en la comunicación con la API' };
            }
        }
        
        // Acciones rápidas
        document.getElementById('quick-backup').addEventListener('click', async () => {
            const resultContainer = document.getElementById('result-container');
            const loading = document.getElementById('loading');
            
            loading.style.display = 'block';
            resultContainer.textContent = 'Realizando backup de todos los dispositivos...';
            
            const result = await callApi('/api/backup', 'POST');
            
            loading.style.display = 'none';
            resultContainer.textContent = JSON.stringify(result, null, 2);
        });
        
        document.getElementById('quick-interfaces').addEventListener('click', async () => {
            const resultContainer = document.getElementById('result-container');
            const loading = document.getElementById('loading');
            
            loading.style.display = 'block';
            resultContainer.textContent = 'Escaneando interfaces...';
            
            const result = await callApi('/api/interfaces');
            
            loading.style.display = 'none';
            resultContainer.textContent = JSON.stringify(result, null, 2);
        });
        
        document.getElementById('quick-ping').addEventListener('click', async () => {
            const resultContainer = document.getElementById('result-container');
            const loading = document.getElementById('loading');
            
            loading.style.display = 'block';
            resultContainer.textContent = 'Realizando ping a 8.8.8.8...';
            
            const result = await callApi('/api/ping', 'POST', { target: '8.8.8.8' });
            
            loading.style.display = 'none';
            resultContainer.textContent = JSON.stringify(result, null, 2);
        });
        
        document.getElementById('quick-ntp').addEventListener('click', async () => {
            const resultContainer = document.getElementById('result-container');
            const loading = document.getElementById('loading');
            
            loading.style.display = 'block';
            resultContainer.textContent = 'Configurando NTP en 172.16.0.10...';
            
            const result = await callApi('/api/ntp', 'POST', { server: '172.16.0.10' });
            
            loading.style.display = 'none';
            resultContainer.textContent = JSON.stringify(result, null, 2);
        });
        
        // Manejo de dispositivos
        document.querySelectorAll('.device-info').forEach(btn => {
            btn.addEventListener('click', async () => {
                const deviceName = btn.getAttribute('data-device');
                const resultContainer = document.getElementById('device-result');
                const loading = document.getElementById('device-loading');
                
                loading.style.display = 'block';
                resultContainer.textContent = `Obteniendo información de ${deviceName}...`;
                
                const result = await callApi(`/api/devices/${deviceName}`);
                
                loading.style.display = 'none';
                resultContainer.textContent = JSON.stringify(result, null, 2);
            });
        });
        
        document.querySelectorAll('.device-interfaces').forEach(btn => {
            btn.addEventListener('click', async () => {
                const deviceName = btn.getAttribute('data-device');
                const resultContainer = document.getElementById('device-result');
                const loading = document.getElementById('device-loading');
                
                loading.style.display = 'block';
                resultContainer.textContent = `Escaneando interfaces de ${deviceName}...`;
                
                const result = await callApi(`/api/interfaces/${deviceName}`);
                
                loading.style.display = 'none';
                resultContainer.textContent = JSON.stringify(result, null, 2);
            });
        });
        
        document.querySelectorAll('.device-backup').forEach(btn => {
            btn.addEventListener('click', async () => {
                const deviceName = btn.getAttribute('data-device');
                const resultContainer = document.getElementById('device-result');
                const loading = document.getElementById('device-loading');
                
                loading.style.display = 'block';
                resultContainer.textContent = `Realizando backup de ${deviceName}...`;
                
                const result = await callApi(`/api/backup/${deviceName}`, 'POST');
                
                loading.style.display = 'none';
                resultContainer.textContent = JSON.stringify(result, null, 2);
            });
        });
        
        // Operaciones avanzadas
        const operationSelect = document.getElementById('operation-select');
        const operationParams = document.getElementById('operation-params');
        const operationDescription = document.getElementById('operation-description');
        const executeButton = document.getElementById('execute-operation');
        
        const operationData = {
            'get-interfaces': {
                description: 'Escanea las interfaces configuradas en un dispositivo específico o en todos los dispositivos.',
                params: [
                    {
                        name: 'device',
                        label: 'Dispositivo',
                        type: 'select',
                        options: [
                            { value: '', label: '-- Todos los dispositivos --' },
                            {% for device_type, devices in device_data.items() %}
                                {% for name, info in devices.items() %}
                                    { value: '{{ name }}', label: '{{ name }} ({{ info.ip }})' },
                                {% endfor %}
                            {% endfor %}
                        ]
                    }
                ]
            },
            'ping-test': {
                description: 'Realiza un test de ping desde los dispositivos hacia una dirección IP específica.',
                params: [
                    {
                        name: 'target',
                        label: 'Dirección IP destino',
                        type: 'input',
                        placeholder: 'Ej: 8.8.8.8',
                        value: '8.8.8.8'
                    }
                ]
            },
            'backup': {
                description: 'Realiza una copia de seguridad de la configuración de un dispositivo específico o de todos los dispositivos.',
                params: [
                    {
                        name: 'device',
                        label: 'Dispositivo',
                        type: 'select',
                        options: [
                            { value: '', label: '-- Todos los dispositivos --' },
                            {% for device_type, devices in device_data.items() %}
                                {% for name, info in devices.items() %}
                                    { value: '{{ name }}', label: '{{ name }} ({{ info.ip }})' },
                                {% endfor %}
                            {% endfor %}
                        ]
                    }
                ]
            },
            'ntp': {
                description: 'Configura un servidor NTP en todos los dispositivos de la red.',
                params: [
                    {
                        name: 'server',
                        label: 'Servidor NTP',
                        type: 'input',
                        placeholder: 'Ej: 172.16.0.10',
                        value: '172.16.0.10'
                    }
                ]
            }
        };
        
        operationSelect.addEventListener('change', () => {
            const operation = operationSelect.value;
            operationParams.innerHTML = '';
            
            if (operation && operationData[operation]) {
                operationDescription.textContent = operationData[operation].description;
                
                // Generar formulario basado en los parámetros
                operationData[operation].params.forEach(param => {
                    const formGroup = document.createElement('div');
                    formGroup.className = 'form-group';
                    
                    const label = document.createElement('label');
                    label.textContent = param.label;
                    label.setAttribute('for', `param-${param.name}`);
                    formGroup.appendChild(label);
                    
                    if (param.type === 'select') {
                        const select = document.createElement('select');
                        select.id = `param-${param.name}`;
                        select.name = param.name;
                        
                        param.options.forEach(option => {
                            const opt = document.createElement('option');
                            opt.value = option.value;
                            opt.textContent = option.label;
                            select.appendChild(opt);
                        });
                        
                        formGroup.appendChild(select);
                    } else if (param.type === 'input') {
                        const input = document.createElement('input');
                        input.id = `param-${param.name}`;
                        input.name = param.name;
                        input.type = 'text';
                        input.placeholder = param.placeholder || '';
                        if (param.value) input.value = param.value;
                        
                        formGroup.appendChild(input);
                    }
                    
                    operationParams.appendChild(formGroup);
                });
                
                executeButton.disabled = false;
            } else {
                operationDescription.textContent = 'Selecciona una operación para ver su descripción...';
                executeButton.disabled = true;
            }
        });
        
        executeButton.addEventListener('click', async () => {
            const operation = operationSelect.value;
            const resultContainer = document.getElementById('operation-result');
            const loading = document.getElementById('op-loading');
            
            if (!operation || !operationData[operation]) return;
            
            // Recopilar parámetros
            const params = {};
            operationData[operation].params.forEach(param => {
                const element = document.getElementById(`param-${param.name}`);
                if (element) {
                    params[param.name] = element.value;
                }
            });
            
            loading.style.display = 'block';
            resultContainer.textContent = 'Ejecutando operación...';
            
            let result;
            
            switch (operation) {
                case 'get-interfaces':
                    if (params.device) {
                        result = await callApi(`/api/interfaces/${params.device}`);
                    } else {
                        result = await callApi('/api/interfaces');
                    }
                    break;
                case 'ping-test':
                    result = await callApi('/api/ping', 'POST', { target: params.target });
                    break;
                case 'backup':
                    if (params.device) {
                        result = await callApi(`/api/backup/${params.device}`, 'POST');
                    } else {
                        result = await callApi('/api/backup', 'POST');
                    }
                    break;
                case 'ntp':
                    result = await callApi('/api/ntp', 'POST', { server: params.server });
                    break;
            }
            
            loading.style.display = 'none';
            resultContainer.textContent = JSON.stringify(result, null, 2);
        });
    </script>
</body>
</html>
"""

# Rutas
@app.route('/')
def index():
    """Página de inicio con dashboard interactivo"""
    try:
        data = load_devices()
        if data and 'devices' in data:
            routers_count = len(data['devices']['routers'])
            switches_count = len(data['devices']['switches'])
            current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            return render_template_string(
                INTERACTIVE_DASHBOARD, 
                request=request, 
                device_data=data['devices'],
                routers_count=routers_count,
                switches_count=switches_count,
                current_time=current_time
            )
        else:
            return "Error: No se pudieron cargar los dispositivos"
    except Exception as e:
        logger.error(f"Error en página principal: {e}")
        return f"Error: {str(e)}"

# Recursos API
class HealthResource(Resource):
    def get(self):
        """Verificar estado de API"""
        return jsonify({
            "status": "online",
            "timestamp": datetime.datetime.now().isoformat(),
            "service": "Network Automation API",
            "version": "1.0.0"
        })

class DevicesResource(Resource):
    def get(self):
        """Obtener lista de dispositivos"""
        data = load_devices()
        if not data:
            return jsonify({"error": "No se pudieron cargar dispositivos"})
        
        # Formatear respuesta
        result = {
            "routers": [],
            "switches": []
        }
        
        for name, info in data['devices']['routers'].items():
            result['routers'].append({
                "name": name,
                "ip": info['ip']
            })
        
        for name, info in data['devices']['switches'].items():
            result['switches'].append({
                "name": name,
                "ip": info['ip']
            })
        
        return jsonify(result)

class DeviceResource(Resource):
    def get(self, device_name):
        """Obtener información de un dispositivo específico"""
        data = load_devices()
        if not data:
            return jsonify({"error": "No se pudieron cargar dispositivos"})
        
        # Buscar en routers y switches
        for device_type in ['routers', 'switches']:
            if device_name in data['devices'][device_type]:
                info = data['devices'][device_type][device_name]
                return jsonify({
                    "name": device_name,
                    "type": device_type[:-1],  # Quitar 's' final
                    "ip": info['ip'],
                    "device_type": info['type']
                })
        
        return jsonify({"error": f"Dispositivo {device_name} no encontrado"})

class InterfacesResource(Resource):
    def get(self):
        """Obtener interfaces de todos los dispositivos"""
        try:
            # Ejecutar comando de escaneo de interfaces
            cmd = [sys.executable, os.path.join(SCRIPTS_DIR, "network_admin.py"), "--interfaces"]
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()
            
            # Leer archivo de log para recuperar información
            with open(os.path.join(LOG_DIR, "network_admin.log"), "r") as f:
                logs = f.readlines()
            
            # Extraer información de logs
            interfaces = {}
            current_device = None
            for line in logs:
                if "Escaneadas " in line and " interfaces de " in line:
                    parts = line.split("Escaneadas ")[1].split(" interfaces de ")
                    if len(parts) == 2:
                        count = parts[0].strip()
                        device = parts[1].strip()
                        interfaces[device] = count
            
            return jsonify({
                "devices": interfaces,
                "details": stdout.decode('utf-8', errors='replace')
            })
        except Exception as e:
            logger.error(f"Error obteniendo interfaces: {e}")
            return jsonify({"error": str(e)})

class DeviceInterfacesResource(Resource):
    def get(self, device_name):
        """Obtener interfaces de un dispositivo específico"""
        try:
            # Import aquí para evitar problemas de circularidad
            sys.path.append(SCRIPTS_DIR)
            from network_admin import get_interfaces, load_devices
            
            # Cargar datos del dispositivo
            data = load_devices()
            if not data:
                return jsonify({"error": "No se pudieron cargar dispositivos"})
            
            # Buscar dispositivo
            device_info = None
            device_type = None
            for dtype in ['routers', 'switches']:
                if device_name in data['devices'][dtype]:
                    device_info = data['devices'][dtype][device_name]
                    device_type = dtype
                    break
            
            if not device_info:
                return jsonify({"error": f"Dispositivo {device_name} no encontrado"})
            
            # Obtener interfaces
            interfaces = get_interfaces(device_name, device_info)
            if not interfaces:
                return jsonify({"error": f"No se pudieron obtener interfaces de {device_name}"})
            
            return jsonify({
                "device": device_name,
                "type": device_type,
                "interfaces": interfaces
            })
        except Exception as e:
            logger.error(f"Error obteniendo interfaces de {device_name}: {e}")
            return jsonify({"error": str(e)})

class BackupResource(Resource):
    def post(self):
        """Realizar backup de todos los dispositivos"""
        try:
            # Ejecutar comando de backup
            cmd = [sys.executable, os.path.join(SCRIPTS_DIR, "network_admin.py"), "--backup"]
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()
            
            return jsonify({
                "status": "success",
                "message": "Backup iniciado",
                "output": stdout.decode('utf-8', errors='replace')
            })
        except Exception as e:
            logger.error(f"Error realizando backup: {e}")
            return jsonify({"error": str(e)})

class DeviceBackupResource(Resource):
    def post(self, device_name):
        """Realizar backup de un dispositivo específico"""
        try:
            # Import aquí para evitar problemas de circularidad
            sys.path.append(SCRIPTS_DIR)
            from network_admin import backup_device_config, load_devices
            
            # Cargar datos del dispositivo
            data = load_devices()
            if not data:
                return jsonify({"error": "No se pudieron cargar dispositivos"})
            
            # Buscar dispositivo
            device_info = None
            for dtype in ['routers', 'switches']:
                if device_name in data['devices'][dtype]:
                    device_info = data['devices'][dtype][device_name]
                    break
            
            if not device_info:
                return jsonify({"error": f"Dispositivo {device_name} no encontrado"})
            
            # Realizar backup
            result = backup_device_config(device_name, device_info)
            if not result:
                return jsonify({"error": f"Error realizando backup de {device_name}"})
            
            return jsonify({
                "status": "success",
                "device": device_name,
                "backup_file": result
            })
        except Exception as e:
            logger.error(f"Error realizando backup de {device_name}: {e}")
            return jsonify({"error": str(e)})

class PingResource(Resource):
    def post(self):
        """Verificar conectividad desde dispositivos a una IP"""
        try:
            # Obtener IP destino
            request_data = request.get_json()
            if not request_data or 'target' not in request_data:
                return jsonify({"error": "Se requiere parámetro 'target'"})
            
            target_ip = request_data['target']
            
            # Ejecutar comando de ping
            cmd = [sys.executable, os.path.join(SCRIPTS_DIR, "network_admin.py"), "--ping", target_ip]
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()
            
            return jsonify({
                "status": "success",
                "target": target_ip,
                "output": stdout.decode('utf-8', errors='replace')
            })
        except Exception as e:
            logger.error(f"Error ejecutando ping: {e}")
            return jsonify({"error": str(e)})

class NTPResource(Resource):
    def post(self):
        """Configurar NTP en dispositivos"""
        try:
            # Obtener servidor NTP
            request_data = request.get_json()
            if not request_data or 'server' not in request_data:
                return jsonify({"error": "Se requiere parámetro 'server'"})
            
            ntp_server = request_data['server']
            
            # Ejecutar comando de NTP
            cmd = [sys.executable, os.path.join(SCRIPTS_DIR, "network_admin.py"), "--ntp", ntp_server]
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()
            
            return jsonify({
                "status": "success",
                "ntp_server": ntp_server,
                "output": stdout.decode('utf-8', errors='replace')
            })
        except Exception as e:
            logger.error(f"Error configurando NTP: {e}")
            return jsonify({"error": str(e)})

# Registrar recursos
api.add_resource(HealthResource, '/api/health')
api.add_resource(DevicesResource, '/api/devices')
api.add_resource(DeviceResource, '/api/devices/<string:device_name>')
api.add_resource(InterfacesResource, '/api/interfaces')
api.add_resource(DeviceInterfacesResource, '/api/interfaces/<string:device_name>')
api.add_resource(BackupResource, '/api/backup')
api.add_resource(DeviceBackupResource, '/api/backup/<string:device_name>')
api.add_resource(PingResource, '/api/ping')
api.add_resource(NTPResource, '/api/ntp')

# Punto de entrada principal
if __name__ == '__main__':
    # Crear directorios si no existen
    os.makedirs(LOG_DIR, exist_ok=True)
    
    # Intentar cargar configuración para validar
    devices = load_devices()
    if devices:
        logger.info(f"Configuración cargada: {len(devices['devices']['routers'])} routers, {len(devices['devices']['switches'])} switches")
    else:
        logger.warning("No se pudo cargar la configuración de dispositivos")
    
    # Iniciar aplicación
    app.run(host='0.0.0.0', port=5000, debug=True)
