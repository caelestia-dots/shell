# Changelog

Cambios relevantes de este fork respecto a releases internas. El detalle de uso está en [FEATURES.md](./FEATURES.md).

## 2026-10-29

### Aislamiento de Plasma (fase 1)

- **Login**: plasmalogin → greetd + tuigreet con autologin a Hyprland (`[initial_session]` en `/etc/greetd/config.toml`; tras logout queda el greeter tuigreet). plasmalogin instalado pero deshabilitado.
- **Qt sin plasma-integration**: `QT_QPA_PLATFORMTHEME=kde → qt6ct` en `shell.qml`, `hyprland.lua` y `environment.d`. Los apps Qt pasan de Breeze a Fusion con la **paleta Material**: `caelestia-quiet.py` genera en cada cambio de esquema `~/.config/qt6ct/colors/caelestia.conf` (22 roles de QPalette desde los tokens Material) + `qt6ct.conf` (Papirus por modo, Fusion), con escritura atómica para el hot-reload de qt6ct.
- **Thunar sin Dolphin**: `plasma-dolphin`/`plasma-kactivitymanagerd` parados y enmascarados (user systemd); override D-Bus de `org.freedesktop.FileManager1` a Thunar (`~/.local/share/dbus-1/services/`). "Open containing folder" y similares ya no suben Dolphin.
- **`colorreload-gtk-module` vendorizado** en `~/.local/share/gtk-3.0/modules/` (copia del .so de kde-gtk-config): la recarga en vivo de Thunar sobrevive a la desinstalación de Plasma.
- **Cursor unificado**: `breeze_cursors → Adwaita` (`gsettings`, `settings.ini`, `XCURSOR_THEME`/`HYPRCURSOR_THEME` en `hyprland.lua`).
- Todo lo demás (iconos de apps, GTK live-reload, portales) sigue igual — queda un dual-write de `kdeglobals [Icons]` mientras `plasma-integration` siga instalada (se retira en fase 2).

### Sync upstream

- Merge de `upstream/main` (PR #1: `feat(lock): clear password with Ctrl+U`). El fork lleva remote `upstream` (caelestia-dots/shell); las actualizaciones de base se hacen mergeando upstream y pasando PR a `main`.
- `.cursor-tmp/` añadido a `.gitignore`.

### Repaso integral de calidad (fixes)

- **Clipboard**: el contenido del portapapeles ya no se interpola en cadenas `sh -c` (va por argv `"$1"`, era inyección); verificación en lote de que el fichero de una imagen existe (texto que acaba en `.jpg` ya no aparece como imagen rota); miniaturas decodificadas al tamaño del thumb (`sourceSize`); favoritos binarios emparejados por id de cliphist.
- **Madison VPN**: el status en cola ya no resetea `busy` en mitad de un connect/disconnect (antes re-habilitaba el botón y un segundo intento mataba el túnel); el script local `disconnect_vpn.sh` ya no duplica la notificación.
- **Activities**: verificación de inicial del look capada a 3 reintentos (un esquema corrupto ya no relanza el apply python sin fin) y `lastAppliedStyleKey` solo se confirma con exit 0.
- **Requests (plugin C++)**: `get` con transfer timeout de 15 s; el plugin se compila a `~/.local` y `shell.qml` lo carga con `QT_ADDITIONAL_PACKAGES_PREFIX_PATH` (sin sudo).
- **Updates**: la contraseña del sudo vive solo en RAM (`sudo -S -v` por paso en `run-system-update.sh`, sin fichero de askpass); el timeout de instalación solo corta si lleva 45 min sin imprimir nada (heartbeat por línea de log).
- **Pantalla**: refresh automático en `monitoradded`/`monitorremoved` y `persist()` conserva las políticas VRR de outputs desenchufados.
- **Juegos (Steam)**: muestreo de logros capado a 60 juegos (los más jugados) y refresco periódico solo con la pestaña Juegos visible.
- **OpenCode**: tema `caelestia` con gemelas `caelestia`/`caelestia-alt` para el hot-reload por flip de nombre; `generate-opencode-theme.py` calcula `pick_sources()` una sola vez.

### Nexus → Pantalla (Display)

- Nueva página en Connectivity (encima de Audio): una tarjeta por monitor con **modo (Hz)**, **escala** y **VRR / Adaptive Sync**.
- Política VRR estilo Plasma: **Nunca / Automático / Siempre** (Automático = solo a pantalla completa).
- Persistencia por conector en `~/.config/hypr/caelestia-monitors.lua` + `hyprctl reload` al aplicar; la política guardada ya no la pisa el booleano de `hyprctl` (fix del parpadeo con Adaptive Sync pegado en el CRTC). Requiere `require("caelestia-monitors")` en `hyprland.lua`.

### Layout compacto (ex game mode)

- Redefinido como layout que aprovecha la pantalla al máximo: sin marco de Caelestia (solo barra izquierda, `reserved: 60 0 0 0`), gaps 0, `rounding`/`border_size` 0 y sin hueco entre barra y ventanas (smoothing 0 + solape 1px).
- Ya **no** toca animaciones, blur, sombras, wobble ni tearing. El id interno sigue siendo `gameMode` (IPC / quick toggle `fit_screen`).

## 2026-10-28

### Juegos (Steam)

- Pestaña **Juegos** en el dashboard (complemento opt-in): perfil, stats Material You, hero, selector por última partida.
- Lista única de logros (scroll): desbloqueados por rareza, luego bloqueados; descripciones siempre visibles.
- Mapa de calor mensual con navegación entre meses; puntos en días con logros.
- Juegos no Steam (`shortcuts.vdf` + arte local); filtra la colección Hidden de Steam.
- Horas no Steam vía plugin Millennium; sesiones Steam vía `reaper` + delta de playtime.
- Refresco automático configurable en Nexus (default 10 min); la API key va oculta, con botón de mostrar.
- Al refrescar se conserva el juego seleccionado.

### Notificaciones / hidratación / tiempo

- Hover en las esquinas derecha abre la sidebar de notificaciones.
- Hidratación: persistencia del último recordatorio para no repetirlo al reiniciar la shell.
- Amanecer/atardecer en 24 h usan `HH:mm` (antes se mostraban en ciclo 1–12).

### Higiene

- `.gitignore` cubre `__pycache__/` de los scripts Python.

## 2026-10-27

### System updates

- Página **Nexus → Updates** (lista desplegable, refrescar, actualizar sistema / paquete).
- Fuentes configurables (Arch, AUR, Flatpak; todas on por defecto); wrapper AUR default **yay**.
- Icono en la pastilla de status (junto a VPN) solo si hay updates; popout rápido + enlace a Nexus.
- Poll cada 30 min; toast de paquetes nuevos (configurable, default on).
- Actualizar sistema: password popup → fondo desde el panel / logs en Nexus; toast al terminar.

### Clipboard

- Historial flotante estilo Plasma/Caelestia (`cliphist`): **Super+Shift+V** (remapeable).
- Pegado directo en la ventana enfocada (`wtype` Ctrl+V).
- Favoritos persistentes, búsqueda, miniaturas de imagen.
- Rutas/`file://` a imagen desde el explorador se muestran y pegan como imagen.
- Misma superficie/blur que el panel izquierdo; límite configurable (default 50) en Nexus → Services.

### Complementos / Madison VPN / Timers

- **Nexus → Complementos**: toggles Madison VPN + Timers (iconos `verified_user` / `timer`).
- VPN off: oculta icono, para poll, teardown disconnect+heal.
- Timers off: limpia timers activos y oculta la sección en el popout del reloj.
- Icono VPN en la pastilla de status (bajo Bluetooth) cuando el complemento está on.
- Clic = conectar (diálogo OTP Caelestia) / desconectar.
- Engranaje en el popout: editar config local de openfortivpn (sin secretos en el repo).
- Scripts en `madison_vpn_widget` (`hyprland/`) instalados a `~/.local/share/madison-vpn/`.
- Tras **suspender/reanudar**: health-check (ping a intranet); si el túnel está zombie se limpia y el icono pasa a desconectado (toast). Comando `madison-vpn heal` + `heal_vpn.sh`.

### Activities / tema

- Apply de look **atómico y fiable**: `scripts/apply-activity-style.py` (wallpaper + un solo `scheme set`, sin carrera light/dark).
- Modo/variant de la activity tienen prioridad sobre `smartScheme` (luminancia del wallpaper).
- Verify + reintento si el modo no cuadra tras el apply.
- **GTK/Thunar** siguen el esquema dinámico de la activity (`enableGtk` siempre on; `colors.css` para `colorreload`).
- **Apps claras** de la activity: `prefer-light` + sin motor Qt oscuro; Thunar puede seguir el CSS del esquema.
- Iconos del launcher vía tema KDE: sync **Papirus** en `kdeglobals` desde `caelestia-quiet.py` (ya no depende solo de Breeze).

### Grabación de pantalla

- Carpeta por defecto: `~/Vídeos/Videocapturas de pantalla` (`CAELESTIA_RECORDINGS_DIR` / `Paths.recsdir`).
- Wrappers `record-start.sh` / `record.sh` fijan esa ruta al start/stop/pause.
- Abrir carpeta desde la lista usa el explorador configurado (`thunar` por defecto).
- Reproducir (▶) abre con `apps.playback` (**VLC** por defecto); MIME `video/*` también apunta a VLC.

### Explorador / Hyprland

- **Thunar** como file manager por defecto (`xdg-mime` + Super+E vía `apps.explorer`).
- Dependencias recomendadas para theming: `adw-gtk-theme`, `papirus-icon-theme`, `hyprpolkitagent` (diálogos pkexec).

### Utilities

- **Mantener activo** pasa a interruptor rápido (icono café, a la izquierda del gamepad); la card grande queda desactivada por defecto.
- Idle inhibit **activado por defecto** (`RuntimeState.inhibitIdle`) para no suspender por inactividad.

### Capturas

- Captura a portapapeles (picker) **sin notificación**.

## 2026-10-26

### Launcher

- Menú contextual al clic derecho sobre apps (editar `.desktop`, favoritos, ocultar, restablecer).
- Diálogo de edición centrado (`DesktopEditDialog`) con selector de icono; el launcher no se cierra al editar.
- Un solo menú contextual abierto a la vez (`Menus.qml`); el clic en ítems funciona sobre el texto.
- Overrides de `.desktop` resueltos y guardados de forma fiable en `~/.local/share/applications`.

### Grabación de pantalla

- Arranque desacoplado del panel (`scripts/record-start.sh` + `execDetached`) para que no se cancele al salir el ratón o cambiar de workspace.
- Utilities/sidebar se mantienen abiertos mientras `Recorder.running` / `arming`.
- Indicador **REC** / **PAUSE** bajo el reloj en la barra.
- El botón principal no re-dispara start durante una captura activa.

### Activities / tema

- Overview: arrastrar ventanas entre desktops/activities y enfocar el destino al soltar.
- Estilo por activity al cambiar de foco (wallpaper, esquema, modo, transparency, light apps).
- Integración Kitty: plantilla de usuario, `include` del tema generado, recarga en vivo al cambiar activity.
- `caelestia-quiet.py` recarga Kitty tras aplicar colores; `sync-light-apps-cli.py` conserva el hook de recarga (ya no lo pisa).

### Barra / UI

- Centrado estable del reloj.
- Traducciones ES ampliadas para las cadenas nuevas.
