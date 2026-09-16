# 📋 GUÍA DE CORRECCIÓN — Inception (smikhail)

> Este documento es para mostrar al corrector durante la evaluación.
> Sigue los pasos en orden y usa los comandos exactos de cada sección.

---

## ⚠️ PASO 0 — Limpieza inicial (el corrector lo ejecuta)

El corrector ejecutará este comando antes de empezar:

```bash
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

Respuesta esperada: puede dar algunos errores si no hay nada que borrar. Es normal.

---

## 📁 PASO 1 — Clonar el repositorio

```bash
git clone <URL_DE_TU_REPO> inception
cd inception
```

Verificar que existe la estructura:
```bash
ls -la
# Debe verse: Makefile  README.md  USER_DOC.md  DEV_DOC.md  srcs/  .gitignore

ls srcs/
# Debe verse: .env  docker-compose.yml  requirements/

ls srcs/requirements/
# Debe verse: nginx/  wordpress/  mariadb/
```

---

## 📄 PASO 2 — Verificar README.md

```bash
head -1 README.md
```

✅ Primera línea exacta:
```
*This project has been created as part of the 42 curriculum by smikhail*
```

```bash
# Verificar que existen USER_DOC.md y DEV_DOC.md y no están vacíos
wc -l USER_DOC.md DEV_DOC.md
```

---

## 🔍 PASO 3 — Verificar docker-compose.yml (el corrector lo lee)

```bash
cat srcs/docker-compose.yml
```

El corrector verifica:
- ❌ NO aparece `network: host`
- ❌ NO aparece `links:`
- ✅ SÍ aparece `networks:` (la red `inception`)

```bash
# Buscar explícitamente estas palabras prohibidas (deben salir vacío):
grep -n "network: host" srcs/docker-compose.yml
grep -n "links:" srcs/docker-compose.yml
```

---

## 🔍 PASO 4 — Verificar Makefile y scripts (sin --link)

```bash
grep -r "--link" Makefile srcs/
```

✅ Respuesta esperada: sin output (no existe `--link` en ningún sitio)

---

## 🔍 PASO 5 — Verificar Dockerfiles

```bash
# Ver todos los Dockerfiles
cat srcs/requirements/nginx/Dockerfile
cat srcs/requirements/wordpress/Dockerfile
cat srcs/requirements/mariadb/Dockerfile
```

El corrector verifica:
- ✅ Cada Dockerfile empieza con `FROM debian:bullseye`
- ✅ No hay `tail -f`, `sleep infinity`, ni `bash` suelto en ENTRYPOINT
- ✅ No hay procesos en background (`&`) en los ENTRYPOINTs

```bash
# Verificar que los scripts de ENTRYPOINT no tienen bucles infinitos ni & al final
grep -n "tail -f\|sleep infinity\|tail -f /dev/null" srcs/requirements/*/tools/*.sh
```

✅ Respuesta esperada: sin output

---

## 🚀 PASO 6 — Ejecutar el Makefile

```bash
make
```

Esto:
1. Crea `/home/smikhail/data/wordpress` y `/home/smikhail/data/mariadb`
2. Construye las 3 imágenes Docker desde cero
3. Arranca los 3 contenedores

Esperar a que termine (puede tardar 2-5 minutos la primera vez por las descargas).

---

## ✅ PASO 7 — Verificar que los contenedores están corriendo

```bash
docker compose -f srcs/docker-compose.yml ps
```

Resultado esperado:
```
NAME        IMAGE       STATUS    PORTS
mariadb     mariadb     running   3306/tcp
nginx       nginx       running   0.0.0.0:443->443/tcp
wordpress   wordpress   running   9000/tcp
```

---

## 🌐 PASO 8 — Verificar NGINX (SSL/TLS)

```bash
# Puerto 80 NO debe funcionar
curl -k http://smikhail.42.fr
# Respuesta esperada: connection refused o timeout ✅

# Puerto 443 SÍ debe funcionar
curl -k https://smikhail.42.fr
# Respuesta esperada: HTML de WordPress ✅
```

En el navegador: abrir **https://smikhail.42.fr**
- Aparece advertencia de certificado autofirmado → clic en "Avanzado" → "Continuar"
- Debe verse el sitio WordPress (NO la página de instalación)

---

## 🔒 PASO 9 — Verificar TLS 1.2 / TLS 1.3

```bash
# Verificar versión TLS
openssl s_client -connect smikhail.42.fr:443 -tls1_2 2>/dev/null | grep "Protocol\|Cipher"
openssl s_client -connect smikhail.42.fr:443 -tls1_3 2>/dev/null | grep "Protocol\|Cipher"

# Verificar que TLS 1.0 NO funciona
openssl s_client -connect smikhail.42.fr:443 -tls1 2>/dev/null | grep "handshake failure\|alert"
```

---

## 🐳 PASO 10 — Verificar Docker Network

```bash
docker network ls
```

Resultado esperado: debe aparecer la red `inception`

```bash
docker network inspect inception
```

Debe mostrar los 3 contenedores conectados a esta red.

**Explicación para el corrector:**
> La red `inception` es una red bridge de Docker. Permite que los contenedores se comuniquen entre sí usando su nombre como hostname (DNS interno de Docker). Por ejemplo, WordPress se conecta a MariaDB usando el hostname `mariadb`, y NGINX se conecta a WordPress usando `wordpress`. Desde fuera de la red solo es accesible el puerto 443 de NGINX.

---

## 💾 PASO 11 — Verificar Volúmenes (WordPress)

```bash
docker volume ls
```

Resultado esperado: aparecen `wordpress_data` y `mariadb_data`

```bash
docker volume inspect wordpress_data
```

Buscar en el output:
```json
"Options": {
    "device": "/home/smikhail/data/wordpress",
    "o": "bind",
    "type": "none"
}
```

✅ El `device` debe contener `/home/smikhail/data/`

---

## 💾 PASO 12 — Verificar Volúmenes (MariaDB)

```bash
docker volume inspect mariadb_data
```

Buscar:
```json
"device": "/home/smikhail/data/mariadb"
```

---

## 🌐 PASO 13 — Verificar WordPress en el navegador

1. Abrir **https://smikhail.42.fr**
2. Verificar que carga el sitio WordPress
3. Verificar que NO aparece la página de instalación de WordPress
4. Añadir un comentario con el usuario normal:
   - Usuario: `smikhail_user` / Password: `Us3r_P4ssw0rd_42!`

---

## 👤 PASO 14 — Verificar Admin de WordPress

Abrir **https://smikhail.42.fr/wp-admin**

Credenciales admin:
- Usuario: `smikhail_boss` ← ⚠️ NO contiene "admin" ni "Admin"
- Password: `B0ss_P4ssw0rd_42!`

El corrector verifica:
- ✅ Se puede acceder al panel de administración
- ✅ El username del admin NO contiene "admin"
- ✅ Se puede editar una página y ver los cambios en el frontend

---

## 🗄️ PASO 15 — Verificar MariaDB (no vacía)

```bash
# Entrar a MariaDB
docker exec -it mariadb mariadb -u root -pR00t_P4ssw0rd_42!

# Dentro de MariaDB:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT COUNT(*) FROM wp_posts;
exit
```

Resultado esperado: base de datos `wordpress` con tablas de WordPress y datos.

**Explicación para el corrector:**
> El contenedor MariaDB almacena los datos en `/var/lib/mysql` dentro del contenedor, que está mapeado al volumen `mariadb_data`, que a su vez apunta a `/home/smikhail/data/mariadb` en el host. Por eso los datos persisten aunque el contenedor se reinicie.

---

## 🔄 PASO 16 — Verificar Persistencia (reinicio de VM)

```bash
# Apagar los contenedores
make down

# Simular reinicio (o reiniciar la VM de verdad)
sudo reboot
# ... esperar a que reinicie ...

# Volver a arrancar
make

# Verificar que WordPress sigue configurado (sin página de instalación)
# Verificar que los cambios hechos antes siguen ahí
```

---

## ⚙️ PASO 17 — Modificar configuración de un servicio

El corrector pedirá cambiar el puerto de algún servicio. Ejemplo, cambiar NGINX de 443 a 8443:

```bash
# Editar docker-compose.yml
nano srcs/docker-compose.yml
# Cambiar: 443:443  →  8443:443

# Reconstruir solo el servicio modificado
docker compose -f srcs/docker-compose.yml up -d --build nginx

# Verificar que funciona en el nuevo puerto
curl -k https://smikhail.42.fr:8443
```

---

## 🎓 PREGUNTAS TEÓRICAS — Respuestas rápidas

### ¿Cómo funciona Docker y docker compose?
> Docker empaqueta aplicaciones en contenedores con todo lo que necesitan. Docker compose coordina múltiples contenedores con un archivo YAML y los arranca/para con un solo comando.

### ¿Diferencia entre imagen con y sin docker compose?
> Sin docker compose: construyes con `docker build` y corres con `docker run` manualmente cada vez. Con docker compose: un solo archivo describe todo y `docker compose up` lo gestiona automáticamente, incluyendo redes y volúmenes.

### ¿Beneficio de Docker vs VMs?
> Docker comparte el kernel del host → es mucho más ligero (MB vs GB), arranca en segundos, y es más portable. Las VMs emulan hardware completo con su propio SO, lo que las hace más pesadas pero con mayor aislamiento.

### ¿Por qué esta estructura de directorios?
> El subject requiere que todo el código esté en `srcs/` para separarlo del Makefile raíz. Cada servicio tiene su propia carpeta con Dockerfile y configuración para mantener el código organizado y cada servicio independiente.

### ¿Qué es docker-network?
> Es una red virtual privada que permite a los contenedores comunicarse entre sí por nombre (DNS interno). En este proyecto, NGINX habla con WordPress usando `wordpress:9000` y WordPress habla con MariaDB usando `mariadb:3306`. Desde fuera solo se ve el puerto 443 de NGINX.

---

## 🚨 COMANDOS DE EMERGENCIA

```bash
# Ver logs en tiempo real de un servicio
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f nginx

# Entrar en un contenedor para debug
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

# Rebuild completo desde cero
make fclean && make
```
