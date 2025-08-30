# Local Development Environment

Este directorio contiene la configuración para ejecutar WordPress localmente usando Docker Compose.

## Requisitos Previos

- Docker
- Docker Compose
- Git

## Configuración

1. Copia el archivo de variables de entorno:
```bash
cp .env.example .env
```

2. Edita `.env` y configura una contraseña segura para la base de datos:
```bash
nano .env
```

## Uso

### Levantar el entorno local

Desde este directorio (`infra/environments/local/`):

```bash
docker-compose up -d
```

O desde la raíz del proyecto:

```bash
cd infra/environments/local && docker-compose up -d
```

### Ver logs

```bash
docker-compose logs -f
```

### Detener el entorno

```bash
docker-compose down
```

### Detener y eliminar volúmenes (reset completo)

```bash
docker-compose down -v
```

## Acceso

- WordPress: http://localhost:8000
- Primera vez: Seguir el asistente de instalación de WordPress

## Estructura

- `docker-compose.yml`: Orquestación de servicios (WordPress + MySQL)
- `.env`: Variables de entorno (no versionado)
- `.env.example`: Template de variables de entorno

## Notas

- Los datos de WordPress y MySQL se persisten en volúmenes Docker
- El Dockerfile de producción está en `../../../app/Dockerfile`
- Los plugins personalizados están en `../../../app/src/plugins/`
- La configuración PHP personalizada está en `../../../app/src/config/`