# CCTV NOC Huancayo

## Módulos del informe PDF

El panel cuenta con navegación independiente para:

- **NOC Global:** indicadores, pings de DVR, brillo y gráficas por sede, feed,
  objetos YOLO y ranking de personas.
- **Cámaras:** identificación, estado, latencia, FPS, bitrate, brillo, personas
  y clases detectadas; cada fila abre el detalle.
- **Sedes y Red:** tarjetas y comparativas por sede; inventario con DVR y
  cámaras IP directas, ping y pérdida.
- **Alertas e historial:** conteos por severidad, filtros de período/sede,
  feed, detecciones y ranking.
- **Topología:** mapa jerárquico NOC → sede → DVR/cámaras.
- **Configuración:** alta, edición y retiro de DVR/cámaras; no expone las
  contraseñas, conserva la existente si se deja vacía y evita borrar un DVR
  con cámaras activas. Cada DVR admite usuario, contraseña y puerto RTSP.
- **Administración de usuarios:** cuentas de administrador y operador. El
  operador puede usar los módulos operativos, pero no Configuración ni la
  administración de usuarios.
- **Chat IA / análisis:** asistente generativo local con Ollama, más gráfica e
  historial de brillo por cámara y consultas del historial por período.

La barra superior incluye estado de WebSocket y base de datos, sondeo,
actualización, avisos ON/OFF, modo expandido y tema claro/oscuro.
**Medir ahora** realiza una sola pasada a los equipos configurados aunque el
sondeo periódico esté detenido; pide confirmación y no lo deja activado.

Las gráficas e indicadores solo representan muestras realmente almacenadas.
Si aún no se ejecutó el sondeo, el panel muestra “sin datos” en vez de contar
los dispositivos como caídos. Un DVR solo figura en línea cuando responden el
ping y el puerto TCP RTSP; si alguna condición falla, figura offline. El botón
**Medir DVR** en el panel Ping de DVR consulta ambos indicadores al pulsarlo.
Un canal de cámara solo figura en línea si responde su red y se decodifica un
cuadro RTSP con pérdida de paquetes aceptable; si algún criterio falla, figura
offline.
Si el ping del DVR y su puerto RTSP responden, esa prueba no invalida el estado
de video guardado de sus canales: cada canal se actualiza al recibir su propio
cuadro RTSP. Si el puerto RTSP del DVR no responde, sus canales quedan offline.
En cámaras asociadas a un DVR, el ping verifica la IP del grabador compartida,
no una conexión IP individual de cada canal.
Los conteos del resumen y de cada sede separan online y offline; los equipos sin
una medición se excluyen de ambos conteos y se muestran como “sin medición”.
El FPS se calcula con las marcas de tiempo de los cuadros recibidos (y usa el
tiempo de lectura como respaldo), no con el FPS nominal anunciado por la cámara.
El panel muestra el conteo de personas y las clases YOLO de la última inferencia;
un cero indica que YOLO analizó el cuadro y no detectó personas. Las clases
detectadas se guardan por separado, incluso cuando no hay personas. El bitrate
se calcula en kbps con los bytes de paquetes RTSP recibidos, aunque la cámara no
publique un valor de bitrate en sus metadatos. Requiere el extra de video con
PyAV instalado.

Al iniciar o recargar el inventario, se recupera de la base de datos el último
estado de cada DVR/cámara y la última muestra de video válida. El panel marca
los estados restaurados como guardados e indica la fecha de la muestra; no los
presenta como una comprobación nueva. Al activar el sondeo, los estados se
actualizan con ping y, para cada canal, con un cuadro RTSP real. Si la red
regresa, el siguiente sondeo actualiza automáticamente la conexión y registra
el evento de recuperación. La actualización manual conserva en memoria los
resultados recién medidos.

**Cobertura del inventario:** el PDF describe cinco sedes, seis DVR y 79
cámaras, pero el seed incluido tiene cinco cámaras de muestra. Ese inventario
solo se carga al habilitar explícitamente `SEED_DEMO_DATA=true`; por defecto
las instalaciones nuevas no reciben datos de demostración. Importa el
inventario autorizado real antes de esperar esa cobertura. El PDF también usa
PostgreSQL; el arranque en una PC utiliza SQLite.

El arranque local instala OpenCV para medir video de streams RTSP autorizados.
FPS y brillo requieren cuadros decodificados. Bitrate solo se muestra cuando
el flujo RTSP informa el dato; no se estima desde cuadros. El extra `vision`
activa detección YOLO de personas y objetos en los cuadros muestreados.

## Ejecución local en Windows

1. Instala [uv](https://docs.astral.sh/uv/getting-started/installation/) si
   todavía no está disponible.
2. Desde esta carpeta, ejecuta en PowerShell. El bypass aplica solo a este
   proceso y no modifica la política global del equipo:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\start-local.ps1
   ```

   También puedes iniciar todo con `npm run dev`; no requiere instalar
   dependencias de Node.

   Si CCTV NOC ya está activo en el puerto 9000, el script lo detecta y evita
   intentar iniciar una segunda instancia. Si otro programa ocupa ese puerto,
   indica el conflicto para que puedas liberarlo.

El script instala Python 3.12 si hace falta, crea/sincroniza el entorno virtual,
copia `.env.example` a `.env` si aún no existe y crea la base SQLite. El seed
de demostración está desactivado por defecto y no se elimina el inventario ni
el historial que ya exista. No necesitas instalar PostgreSQL para ejecutarlo.

Abre:

- Panel: <http://127.0.0.1:9000/panel>

En el primer inicio, crea el administrador desde la pantalla de configuración
inicial. Elige un usuario de 3 a 32 caracteres (letras, números, punto, guion o
guion bajo) y una contraseña de al menos 12 caracteres. No hay credenciales
predeterminadas. Después, el administrador puede crear cuentas de operador o
administrador desde **Sistema → Administración de usuarios**.

Detén el servidor con `Ctrl+C`. El inventario e historial SQLite quedan en
`data/cctv_noc.db`; esa carpeta está excluida del control de versiones.

### Video y analítica

`start-local.ps1` instala OpenCV para medir los canales RTSP. En esta instalación,
`CCTV_VISION=1` habilita YOLO y sincroniza el extra de visión al iniciar:

```powershell
.\start-local.ps1
```

La instalación de visión y el modelo `yolov8n.pt` pueden descargar dependencias
grandes la primera vez. Las detecciones se cuentan en el cuadro real muestreado;
no son seguimiento persistente de personas. FPS y brillo solo aparecen tras
recibir cuadros RTSP; el bitrate se calcula con los paquetes RTSP recibidos.

Si RTSP devuelve `401 Unauthorized`, revisa en **Configuración** las credenciales
del DVR y su permiso RTSP. No sigas reintentando automáticamente con una clave
rechazada: el equipo puede bloquear temporalmente la cuenta.

### Asistente IA local

El chat usa Ollama en esta PC y consulta el inventario, los estados, las
mediciones y las alertas almacenadas. No se envían credenciales, IP ni URL
RTSP al modelo. El asistente no ejecuta acciones ni inventa mediciones que no
estén registradas.

1. Instala Ollama para Windows desde <https://ollama.com/download/windows> y
   asegúrate de que esté ejecutándose.
2. En PowerShell descarga el modelo predeterminado:

   ```powershell
   ollama pull qwen2.5:3b
   ```

3. Reinicia `start-local.ps1`, abre **Chat IA** y comprueba que aparezca
   **IA local lista**. El servidor precarga el modelo en segundo plano y lo
   conserva en memoria durante 30 minutos después de la última consulta.

El modelo y el tiempo máximo se pueden ajustar en `.env` con `OLLAMA_MODEL` y
`OLLAMA_TIMEOUT_S`; `OLLAMA_KEEP_ALIVE` controla cuánto permanece cargado el
modelo. `OLLAMA_URL` apunta por defecto a `127.0.0.1:11434`; el asistente solo
acepta direcciones locales para que los datos del sistema no se envíen a un
servicio remoto.

### Equipos monitoreados

El `.env` incluido activa automáticamente solo `DVR-K`, `K01`, `K02` y `K03`
de Kinder. Los demás equipos existentes no se sondean y se muestran como
«sin medición». Al guardar un DVR o una cámara desde Configuración, ese equipo
se agrega a la lista persistente de monitoreo y recibe una medición inmediata
si el sondeo está activo. El alta se conserva tras reiniciar el servidor; no
activa direcciones del inventario de demostración. Las nuevas instalaciones
no agregan inventario de demostración.

### Cargar tus DVR y cámaras

1. Abre **Configuración → Agregar DVR** e ingresa la IP del grabador, su sede,
   usuario, contraseña y puerto RTSP (normalmente `554`).
2. Agrega cada canal en **Agregar cámara**. Selecciona ese DVR e ingresa el
   número de canal; la IP y el puerto se tomarán del grabador. Para cámaras IP
   independientes, deja el DVR como **IP directa** y coloca ahí su IP y
   credenciales.
3. Las contraseñas no vuelven en las respuestas de la API. Al editar, déjalas
   vacías para conservarlas.
4. Con el sondeo activo, al guardar el DVR o la cámara el sistema hará la
   primera medición de inmediato y continuará consultando ese equipo cada
   minuto. Si el sondeo está detenido, el dispositivo queda habilitado y
   aparecerá «sin medición» hasta pulsar **Activar sondeo**. Puedes detenerlo
   desde el mismo botón. El sistema no busca ni descubre automáticamente
   otros equipos.

Para comprobar una IP sin activar el sondeo de todos los equipos, abre
**Red → Probar ping** junto al DVR o cámara. El resultado actualiza el estado y
se guarda como medición; una respuesta ICMP confirma comunicación de red, no
que el video RTSP o todos los canales estén disponibles.

El botón permite iniciar el sondeo sin editar `.env` ni reiniciar. Si quieres
que se active automáticamente cada vez que arranca el servidor, cambia
`MONITORING_ENABLED=true` en `.env`. Mantén el servidor accesible solo desde
un equipo/red de confianza. Las contraseñas de las cuentas se almacenan con
hash; las credenciales RTSP de los dispositivos siguen guardándose localmente
en SQLite sin cifrado, así que protege el equipo y las copias de
`data/cctv_noc.db`.

### Acceso desde otro equipo de la red local

Solo si lo necesitas, inicia escuchando en la red:

```powershell
$env:CCTV_HOST = "0.0.0.0"
.\start-local.ps1
```

Luego abre `http://<IP-de-esta-PC>:9000/panel` desde el otro equipo e inicia
sesión con una cuenta creada por el administrador. Limita el acceso a una red
de confianza y no publiques el puerto en Internet.

## PostgreSQL

Para usar PostgreSQL en lugar de la base local:

1. Configura un servidor PostgreSQL y ejecuta, en orden, `database/schema.sql`
   y `database/seed.sql`.
2. En `.env`, cambia `DATABASE_URL` por la cadena PostgreSQL local.
   `start-local.ps1` instala el controlador PostgreSQL al detectar esa URL.
3. Inicia el servidor con el comando local habitual:

   ```powershell
   .\start-local.ps1
   ```

No ejecutes el seed de demostración sobre una base que ya tenga el inventario.
