# Changelog

Cambios relevantes de este fork respecto a releases internas. El detalle de uso está en [FEATURES.md](./FEATURES.md).

## 2026-10-27

### Clipboard

- Historial flotante estilo Plasma/Caelestia (`cliphist`): **Super+Shift+V** (remapeable).
- Pegado directo en la ventana enfocada (`wtype` Ctrl+V).
- Favoritos persistentes, búsqueda, miniaturas de imagen.
- Rutas/`file://` a imagen desde el explorador se muestran y pegan como imagen.
- Misma superficie/blur que el panel izquierdo; límite configurable (default 50) en Nexus → Services.

### Madison VPN

- Icono VPN en la pastilla de status (bajo Bluetooth).
- Clic = conectar (diálogo OTP Caelestia) / desconectar.
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
