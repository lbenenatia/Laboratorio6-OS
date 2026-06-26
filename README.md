# Lab 06 — DevOps Moderno con GitHub Actions

> UCU · Sistemas Operativos · Pipeline CI/CD completo con despliegue en Azure

## Servicios

| App     | Descripción                              | Puerto |
|---------|------------------------------------------|--------|
| Dummy A | Sitio estático HTML servido por NGINX    | 80     |
| Dummy B | Flask API con endpoint `/health`         | 8080   |

## Setup rápido

### 1. Configurar secretos en GitHub

`Settings → Secrets and variables → Actions → New repository secret`

| Secret                  | Valor                              |
|-------------------------|------------------------------------|
| `AZURE_VM_HOST`         | IP pública de la VM                |
| `AZURE_VM_USER`         | Usuario SSH (ej: `ubuntu`)         |
| `AZURE_SSH_PRIVATE_KEY` | Contenido completo de tu clave .pem|

### 2. Preparar la VM (una sola vez)

```bash
# En la VM, como root:
sudo bash scripts/setup_vm.sh
```

### 3. Hacer push a main para disparar el pipeline

```bash
git add .
git commit -m "feat: initial devops setup"
git push origin main
```

El pipeline CI/CD se dispara automáticamente.

## Estructura

```
.github/workflows/
  ci.yml        # Validación, tests, empaquetado
  cd.yml        # Deploy SSH a Azure VM
app/
  dummy-a/      # HTML estático
  dummy-b/      # Flask API
scripts/
  setup_vm.sh   # Setup inicial (una vez)
  deploy.sh     # Deploy automatizado (cada CI/CD)
nginx/
  dummy-a.conf  # Config NGINX
systemd/
  dummy-b.service # Servicio Flask
```
