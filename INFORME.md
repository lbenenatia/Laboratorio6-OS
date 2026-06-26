# INFORME — Laboratorio 06: DevOps Moderno con GitHub Actions

**Estudiante:** [Tu nombre aquí]  
**Fecha:** [Fecha de entrega]  
**Repositorio:** https://github.com/lbenenatia/Laboratorio6-OS  
**URL pública Dummy A:** `http://<IP_VM>:80`  
**URL pública Dummy B:** `http://<IP_VM>:8080/health`

---

## 1. Pre-Lab — Investigación y Spike Técnico

Este laboratorio implementa un flujo de integración y entrega continua (CI/CD) real, utilizando GitHub Actions para automatizar las etapas de validación, empaquetado y despliegue sobre una máquina virtual Ubuntu en Azure.

### Parte 1 — Introducción a DevOps

**¿Qué es DevOps?**

DevOps es una metodología que une los equipos de desarrollo (Dev) y operaciones (Ops) con el objetivo de acortar el ciclo de vida del software mediante automatización, integración continua y entrega continua.

**Diferencia entre CI y CD**

| Concepto | Descripción |
|----------|-------------|
| **CI** (Continuous Integration) | Automatiza la validación del código en cada push: ejecuta tests, lint y genera un artifact empaquetado. |
| **CD** (Continuous Delivery/Deployment) | Automatiza el despliegue del artifact hacia el ambiente de producción (Azure VM). |

**Beneficios de la automatización**

Reduce errores humanos al eliminar pasos manuales repetitivos, acelera el tiempo de release, garantiza que cada despliegue sea idéntico y repetible, y deja un registro auditable de qué se desplegó y cuándo.

**¿Qué es un pipeline?**

Un pipeline es una secuencia de etapas automatizadas que transforma el código fuente en un servicio corriendo en producción. En este lab: `push → CI (test + package) → CD (deploy SSH) → servicio disponible públicamente`.

**¿Qué es Infrastructure as Code?**

Definición de infraestructura (servidores, redes, servicios) mediante archivos de configuración versionados en lugar de configuración manual. En este lab se utiliza para los archivos YAML de los workflows y los scripts de deploy.

**¿Qué es un despliegue automatizado?**

Es el proceso de llevar una nueva versión de la aplicación a producción sin intervención manual: el propio pipeline copia los archivos al servidor, reinicia los servicios afectados y valida que el servicio quedó disponible, sin que una persona deba conectarse por SSH a hacerlo a mano.

### Parte 2 — Investigación de Plataformas

| Plataforma | Tipo de integración | Característica distintiva |
|---|---|---|
| GitHub Actions | Nativa de GitHub | Workflows en YAML dentro de `.github/workflows/`, runners hospedados gratuitos para repos públicos |
| Azure DevOps Pipelines | Independiente, conecta con cualquier repositorio | Pipelines orientados a empresas, integrados con Boards y Artifacts de Azure DevOps |
| GitLab CI/CD | Nativa de GitLab | Pipeline definido en un único archivo `.gitlab-ci.yml`, con runners propios o compartidos |
| Bitbucket Pipelines | Nativa de Bitbucket | Integración directa con el ecosistema Atlassian (Jira, Trello) |

Para este laboratorio se eligió **GitHub Actions** porque el repositorio ya vive en GitHub y no requiere dar de alta un proyecto ni runners adicionales: alcanza con agregar los archivos YAML en `.github/workflows/`.

### Parte 3 — Investigación Técnica Base

**¿Qué es YAML?**

Un formato de archivo de texto para definir datos estructurados (listas, mapas) de forma legible, usado por GitHub Actions para describir los workflows.

**¿Qué es un runner o agente?**

Es la máquina (física, virtual o un contenedor) que ejecuta los pasos definidos en un workflow. GitHub Actions provee runners hospedados (`ubuntu-latest`) que se levantan automáticamente para cada ejecución.

**¿Qué es un workflow?**

Es el archivo YAML que define cuándo se dispara un pipeline (`on:`) y qué jobs y steps se ejecutan. En este repo: `ci.yml` y `cd.yml`.

**¿Qué es un artifact?**

Es un archivo o conjunto de archivos generado durante un job que se guarda temporalmente para ser reutilizado por otro job o descargado luego de la ejecución. En este lab, el job `package` de CI genera y publica el ZIP de la aplicación.

**¿Qué es SSH?**

Secure Shell, un protocolo que permite conectarse y ejecutar comandos de forma cifrada en un servidor remoto. Se usa en CD para copiar el paquete a la VM y ejecutar `deploy.sh` de forma remota.

**¿Qué es un deployment?**

Es la acción de llevar una versión específica del código a un ambiente donde queda corriendo y accesible (en este caso, la VM Ubuntu en Azure).

**¿Qué es un secreto o variable segura?**

Los secretos son valores sensibles (claves SSH, IPs, usuarios) almacenados de forma cifrada en GitHub Secrets y accesibles en los pipelines como variables de entorno, sin quedar expuestos en los logs ni en el código fuente.

---

## 2. Arquitectura del Proyecto

```
Developer
   ↓ git push a main
GitHub Repository
   ↓
CI Pipeline (.github/workflows/ci.yml)
   ├── Validar HTML Dummy A
   ├── Tests pytest Dummy B
   └── Empaquetar en ZIP (artifact)
        ↓
CD Pipeline (.github/workflows/cd.yml)
   ├── SCP → copiar ZIP a /tmp/ en Azure VM
   ├── SSH → ejecutar /opt/deploy/deploy.sh
   │     ├── Desplegar Dummy A → /var/www/dummy-a (NGINX)
   │     └── Desplegar Dummy B → /opt/dummy-b (Python venv + systemd)
   └── Verificar HTTP 200 en ambos endpoints
        ↓
Azure VM Ubuntu 24.04
   ├── Puerto 80  → NGINX → Dummy A (HTML estático)
   └── Puerto 8080 → Flask → Dummy B (/health endpoint)
```

---

## 3. Estructura del Repositorio

```
lab06-devops/
├── .github/
│   └── workflows/
│       ├── ci.yml          # Pipeline de integración continua
│       └── cd.yml          # Pipeline de entrega continua
├── app/
│   ├── dummy-a/
│   │   └── index.html      # Sitio estático "Hola Mundo DevOps"
│   └── dummy-b/
│       ├── app.py          # Flask API con /health
│       ├── requirements.txt
│       └── test_app.py     # Tests automáticos con pytest
├── scripts/
│   ├── deploy.sh           # Script de despliegue en la VM
│   └── setup_vm.sh         # Setup inicial de la VM (una vez)
├── nginx/
│   └── dummy-a.conf        # Configuración NGINX para Dummy A
├── systemd/
│   └── dummy-b.service     # Servicio systemd para Flask
├── INFORME.md              # Este documento
└── README.md
```

---

## 4. Desarrollo

### 4.1 Configuración de la VM en Azure

Se creó una VM Ubuntu 24.04 LTS (tamaño B1s) con:
- IP pública estática
- NSG permitiendo puertos: 22 (SSH), 80 (HTTP), 8080 (Flask)

Se ejecutó el script `setup_vm.sh` para instalar NGINX, Python, configurar el firewall y los servicios systemd.

### 4.2 Configuración de Secretos en GitHub

Se configuraron los siguientes secretos en `Settings → Secrets and variables → Actions`:

| Secret | Descripción |
|--------|-------------|
| `AZURE_VM_HOST` | IP pública de la VM |
| `AZURE_VM_USER` | Usuario SSH (ej: `ubuntu`) |
| `AZURE_SSH_PRIVATE_KEY` | Clave privada SSH (contenido del archivo .pem) |

### 4.3 Pipeline CI (`ci.yml`)

**Trigger:** `push` y `pull_request` a las ramas `main` y `develop`.

**Jobs:**
1. `validate-dummy-a`: Verifica que `index.html` existe y contiene el mensaje esperado. También ejecuta htmlhint.
2. `test-dummy-b`: Instala dependencias Python, verifica sintaxis y ejecuta 10 tests con pytest.
3. `package`: Ejecuta solo si los dos jobs anteriores pasaron. Genera un ZIP y lo sube como GitHub Artifact.

### 4.4 Pipeline CD (`cd.yml`)

**Trigger:** `workflow_run` cuando CI completa exitosamente en `main`, o `workflow_dispatch` manual.

**Jobs:**
1. Re-empaqueta la aplicación.
2. Configura la clave SSH usando el secret `AZURE_SSH_PRIVATE_KEY`.
3. Copia el ZIP a la VM via SCP.
4. Ejecuta `deploy.sh` remotamente via SSH.
5. Verifica que ambos endpoints devuelven HTTP 200.

### 4.5 Script de Deploy en VM (`deploy.sh`)

El script ejecuta en la VM:
1. Extrae el ZIP recibido.
2. Copia `index.html` a `/var/www/dummy-a/` (servido por NGINX).
3. Copia `app.py` y `requirements.txt` a `/opt/dummy-b/`.
4. Instala dependencias en el virtualenv.
5. Reinicia NGINX y el servicio `dummy-b` (systemd).
6. Verifica localmente ambos endpoints.
7. Limpia archivos temporales.

---

## 5. Problemas Encontrados y Soluciones

| Problema | Causa | Solución |
|----------|-------|----------|
| [Describir problema real] | [Causa] | [Cómo lo resolviste] |
| | | |

---

## 6. Reflexión Técnica

1. **¿Qué ventajas ofrece DevOps frente al despliegue manual?**  
   El despliegue manual es propenso a errores humanos, no es repetible y no tiene trazabilidad. Con DevOps, cada despliegue es idéntico, automatizado, auditado y reversible. El tiempo de release se reduce drásticamente.

2. **¿Qué problemas podrían ocurrir sin automatización?**  
   Configuraciones inconsistentes entre ambientes, archivos olvidados, versiones incorrectas desplegadas, errores difíciles de detectar y sin registro histórico de qué se desplegó cuándo.

3. **¿Qué parte del pipeline fue más compleja?**  
   [Respuesta personal]

4. **¿Qué mejorarían en un ambiente empresarial real?**  
   - Ambientes separados (dev/staging/prod) con aprobaciones manuales para producción.  
   - Tests de integración y carga automatizados.  
   - Rollback automático ante fallos.  
   - Notificaciones a Slack/Teams en cada deploy.

5. **¿Qué riesgos de seguridad identificaron?**  
   - La clave SSH privada debe rotarse periódicamente.  
   - El NSG debe restringirse a IPs conocidas en producción.  
   - Los secretos nunca deben hardcodearse en el código.

6. **¿Cómo escalarían esta solución?**  
   - Contenedores Docker + Kubernetes para escalar horizontalmente.  
   - Azure Container Registry + AKS.  
   - Load Balancer + múltiples instancias de la VM.

---

## 7. Conclusiones

[Escribir 3-4 oraciones con la experiencia personal del laboratorio]

---

## 8. URL Pública del Servicio

| Servicio | URL |
|----------|-----|
| Dummy A (HTML) | `http://<IP_VM>:80` |
| Dummy B /health | `http://<IP_VM>:8080/health` |
| Dummy B / | `http://<IP_VM>:8080` |
