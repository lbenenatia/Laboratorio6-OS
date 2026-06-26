#!/bin/bash

# deploy.sh — Script de despliegue automatizado
# Uso: bash /opt/deploy/deploy.sh /tmp/app-deploy.zip

set -e

ZIP_PATH="${1:-/tmp/app-deploy.zip}"
DEPLOY_DIR="/tmp/deploy-$(date +%s)"
LOG="/var/log/deploy.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

log "Iniciando despliegue"
log "Paquete: $ZIP_PATH"

# 1. Verificar que el paquete existe
log "[1/8] Verificando paquete..."
if [ ! -f "$ZIP_PATH" ]; then
  log "ERROR: No se encontró el paquete $ZIP_PATH"
  exit 1
fi
log "Paquete encontrado: $(du -h $ZIP_PATH | cut -f1)"

# 2. Extraer paquete
log "[2/8] Extrayendo paquete..."
mkdir -p "$DEPLOY_DIR"
unzip -q "$ZIP_PATH" -d "$DEPLOY_DIR"
log "Paquete extraído en $DEPLOY_DIR"

# 3. Desplegar Dummy A (sitio estático)
log "[3/8] Desplegando Dummy A..."
cp -r "$DEPLOY_DIR/app/dummy-a/"* /var/www/dummy-a/
chown -R www-data:www-data /var/www/dummy-a
log "Dummy A desplegado en /var/www/dummy-a"

# 4. Desplegar Dummy B (Flask API)
log "[4/8] Desplegando Dummy B..."
cp "$DEPLOY_DIR/app/dummy-b/app.py"          /opt/dummy-b/app.py
cp "$DEPLOY_DIR/app/dummy-b/requirements.txt" /opt/dummy-b/requirements.txt

log "Instalando dependencias Python..."
/opt/dummy-b/venv/bin/pip install -q -r /opt/dummy-b/requirements.txt
log "Dependencias instaladas"

# 5. Reiniciar servicios
log "[5/8] Reiniciando servicios..."
systemctl reload nginx
log "NGINX reiniciado"

systemctl restart dummy-b
sleep 3
log "Servicio dummy-b reiniciado"

# 6. Verificar que los servicios quedaron activos
log "[6/8] Verificando servicios activos..."
if systemctl is-active --quiet nginx; then
  log "NGINX corriendo correctamente"
else
  log "ERROR: NGINX no está activo"
  exit 1
fi

if systemctl is-active --quiet dummy-b; then
  log "dummy-b corriendo correctamente"
else
  log "ERROR: dummy-b no está activo"
  journalctl -u dummy-b --no-pager -n 20 | tee -a "$LOG"
  exit 1
fi

# 7. Verificar endpoints localmente
log "[7/8] Verificando endpoints localmente..."
sleep 2
HTTP_A=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 || echo "000")
HTTP_B=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")

if [ "$HTTP_A" = "200" ]; then
  log "Dummy A OK (HTTP 200)"
else
  log "Dummy A respondió HTTP $HTTP_A"
fi

if [ "$HTTP_B" = "200" ]; then
  log "Dummy B /health OK (HTTP 200)"
else
  log "Dummy B respondió HTTP $HTTP_B"
fi

# 8. Limpieza
log "[8/8] Limpiando archivos temporales..."
rm -rf "$DEPLOY_DIR" "$ZIP_PATH"
log "Archivos temporales eliminados"

log "Despliegue completado exitosamente"
