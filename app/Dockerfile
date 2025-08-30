# =============================================================================
# PASO 1: Usar la imagen oficial de WordPress como base
# =============================================================================
# Usamos una versión específica (ej: 6.4.3-php8.2-apache) en lugar de 'latest'
# para tener despliegues predecibles y evitar sorpresas.
FROM wordpress:6.4.3-php8.2-apache

# =============================================================================
# PASO 2: Personalizar la configuración de PHP
# =============================================================================
# Copiamos un archivo .ini personalizado para aumentar límites comunes,
# como el tamaño máximo de subida de archivos.
# Esto es útil para subir temas, plugins o multimedia de gran tamaño.
COPY ./src/config/uploads.ini /usr/local/etc/php/conf.d/uploads.ini

# =============================================================================
# PASO 3: Instalar plugins y temas personalizados
# =============================================================================
# Copiamos los plugins y temas desde nuestras carpetas locales al contenedor.
# Esto "pre-instala" el contenido en la imagen.
# El usuario y grupo 'www-data' es el que usa Apache dentro del contenedor.
COPY --chown=www-data:www-data ./src/plugins/ /var/www/html/wp-content/plugins/

# =============================================================================
# PASO 4: Añadir un Health Check
# =============================================================================
# Esto le dice a Docker (y a ECS) cómo verificar si el contenedor está
# funcionando correctamente. Intenta acceder a la página principal.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# =============================================================================
# PASO 5: Exponer el puerto
# =============================================================================
# Documentamos que el contenedor escucha en el puerto 80.
EXPOSE 80
