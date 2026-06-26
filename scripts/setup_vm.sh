#!/bin/bash

# Ejecutar UNA SOLA VEZ con: sudo bash setup_vm.sh

set -e

echo "Setup inicial VM — Lab 06 DevOps UCU"

# 1. Actualizar sistema
echo "[1/7] Actualizando sistema..."
apt-get update -y && apt-get upgrade -y

# 2. Instalar paquetes base
echo "[2/7] Instalando paquetes base..."
apt-get install -y \
  nginx \
  python3 \
  python3-pip \
  python3-venv \
  unzip \
  curl \
  git \
  ufw

# 3. Configurar firewall
echo "[3/7] Configurando firewall UFW..."
ufw allow 22/tcp     # SSH
ufw allow 80/tcp     # HTTP (Dummy A)
ufw allow 8080/tcp   # Flask API (Dummy B)
ufw --force enable
echo "Firewall configurado"

# 4. Crear directorios de la aplicación 
echo "[4/7] Creando directorios..."
mkdir -p /var/www/dummy-a
mkdir -p /opt/dummy-b
mkdir -p /opt/deploy

chown -R www-data:www-data /var/www/dummy-a
chmod -R 755 /var/www/dummy-a

# 5. Configurar entorno Python virtual 
echo "[5/7] Configurando entorno Python..."
python3 -m venv /opt/dummy-b/venv
echo "Virtual env creado en /opt/dummy-b/venv"

# 6. Copiar script de deploy 
echo "[6/7] Instalando script de deploy..."
cp /tmp/lab06/scripts/deploy.sh /opt/deploy/deploy.sh
chmod +x /opt/deploy/deploy.sh
echo "Script de deploy instalado"

# 7. Copiar y activar configuración NGINX 
echo "[7/7] Configurando NGINX..."
cp /tmp/lab06/nginx/dummy-a.conf /etc/nginx/sites-available/dummy-a
ln -sf /etc/nginx/sites-available/dummy-a /etc/nginx/sites-enabled/dummy-a
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
echo "NGINX configurado"

# 8. Instalar y habilitar servicio dummy-b 
echo "[8/8] Configurando servicio systemd dummy-b..."
cp /tmp/lab06/systemd/dummy-b.service /etc/systemd/system/dummy-b.service
systemctl daemon-reload
systemctl enable dummy-b
echo "Servicio dummy-b habilitado"

echo "Setup completado"
